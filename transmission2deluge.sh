#!/bin/bash
#USER VARS -- CHANGE THESE!
#transmisison remote
TUSER="USER"
TPASS="PASS"
THOME="user"
#deluge console
DUSER="USER"
DPASS="PASS"
DIP="127.0.0.1"
DPORT="58846"


#VARIABLES
REMOTE="transmission-remote -n $TUSER:$TPASS"
CONSOLE=$"deluge-console 'connect $DIP:$DPORT $DUSER $DPASS"
TORID=$($REMOTE -l | tail -2 | head -1 | awk '{print $1}') #gets torrent id count
TOR_LOC="/home/$THOME/.config/transmission-daemon/torrents/"

arrFAIL=()
arrCOMPLETE=()
LOG=$(dirname $0)
LOG+="/trans2deluge.log"
DT=$(date '+%Y-%m-%d %H:%M:%S')
VERIFY_INPUT=""


##func
welcome () {
    echo -e "\e[92mVerify torrents in script? [y/n]"
    echo -e "\e[39m"
    read VERIFY_INPUT
    check_welcome
}

check_welcome () {
if [[ "$VERIFY_INPUT" == "y" ]] || [[ "$VERIFY_INPUT" == "Y" ]] || [[ "$VERIFY_INPUT" == "n" ]] || [[ "$VERIFY_INPUT" == "N" ]]
then
    echo -e "OK!"
else
    echo -e ""
    echo -e "\e[104mPlease enter y or n"
    echo -e "\e[49m"
    welcome
fi
}

verify_deluge () {
    local RECHECK="${CONSOLE} ; recheck $1'"
    printf "Verifying..."
    sleep 0.5
    eval $RECHECK
    
    local CHECKPROG="${CONSOLE} ; info -v -i $1'"
    local PROGRESS="0"
    local STATE=$(eval $CHECKPROG | awk '{for(i=1;i<=NF;i++)if ($i=="State:") print $(i+1)}')
    
    while [[ $STATE == "Checking" ]]; do
        read -r STATE PROGRESS <<<$(eval $CHECKPROG | awk '{for(i=1;i<=NF;i++)if ($i=="State:") {print $(i+1)} else if($i=="Progress:") print $(i+1)}' | tr '\n' ' ' )
        echo -en "\r$i"
        printf "\rChecking data: %s" $PROGRESS
        sleep 0.1
    done
    echo ""
    if [[ $STATE == "Paused" ]] && [[ $PROGRESS == "100.00%" ]]; then
        echo "Verification of $1 completed"
        arrCOMPLETE=(${arrCOMPLETE[@]} $1)
    elif [[ $STATE == "Paused" ]]; then
        PROGRESS=$(eval $CHECKPROG | awk '{for(i=1;i<=NF;i++)if ($i=="Progress:") print $(i+1)}')
        if [[ $PROGRESS == "100.00%" ]]; then
            echo "Verification of $1 completed"
            arrCOMPLETE=(${arrCOMPLETE[@]} $1)
        fi
    else
        echo "Verification of $1 failed."
        arrFAIL=(${arrFAIL[@]} $1)
    fi
}

##start
echo "  _____ ___    _   _  _ ___ __  __ ___ ___ ___ ___ ___  _  _  "
echo " |_   _| _ \  /_\ | \| / __|  \/  |_ _/ __/ __|_ _/ _ \| \| | "
echo "   | | |   / / _ \| .\` \__ \ |\/| || |\__ \__ \| | (_) | .\` | "
echo "   |_| |_|_\/_/ \_\_|\_|___/_| .----._|___/___/___\___/|_|\_| "
echo "                             .' .-.  )                        "
echo "                            / .'  / /                         "
echo "                           (_/   / /                          "
echo "                                / /                           "
echo "                               / /                            "
echo "                              . '                             "
echo "                             / /    _.-')                     "
echo "                           .' '  _.'.-''                      "
echo "                          /  /.-'_.'                          "
echo "            ______ _____ /    _.' __ _____  _____             "
echo "            |  _  \  ___( _.-'| | | |  __ \|  ___|            "
echo "            | | | | |__ | |   | | | | |  \/| |__              "
echo "            | | | |  __|| |   | | | | | __ |  __|             "
echo "            | |/ /| |___| |___| |_| | |_\ \| |___             "
echo "            |___/ \____/\_____/\___/ \____/\____/             "
echo "                                                              "
echo ""
command -v deluge-console >/dev/null 2>&1 || { echo >&2 "I require deluge-console but it's not installed.  Aborting."; exit 1; }
command -v transmission-remote >/dev/null 2>&1 || { echo >&2 "I require transmission-remote but it's not installed.  Aborting."; exit 1; }

echo ""
echo "This script can run verification checks on all torrents for you"
echo "the verification is run before adding the next torrent this can"
echo -e "take a \e[1mvery \e[0mlong time depending on size/count of your torrents"
echo ""
echo "If you want to verify torrents in bulk by yourself after they"
echo "have been added to deluge you can disable verification within"
echo "the script and it will only add the torrents to deluge for you"
echo ""
    
welcome

#First we must check add_paused state and change it if required
ADDPAUSED="${CONSOLE} ; config add_paused'"
PAUSEBOOL=$(eval $ADDPAUSED | awk '{if ($1 == "add_paused:") { print $2 } else if($1 != "add_paused:") print $1 }')
ORIG_PAUSE=$PAUSEBOOL

if [[ $PAUSEBOOL == False ]]; then
    echo "Changing add_paused to True while script runs to avoid accidental downloading"
    SETPAUSED="${CONSOLE} ; config -s add_paused True'"
    eval $SETPAUSED
    PAUSEBOOL="True"
elif
   [[ $PAUSEBOOL != True ]]; then
   echo "Failed to read config add_paused correctly, returned value was: $PAUSEBOOL, should be True or False"; exit 1;
fi

#loop through torrent ids
# get hash for each torrent and get its torrent file
# check if same hash exists in deluge already or not
# add torrent to deluge and set data location from transmission
# verify torrent data 

echo ""
echo "Adding torrents, press 'q' to quit after next completed torrent"
echo ""

for (( t=1; t<=$TORID; t++ ))
    do
        echo "Looking to move torrent ID: $t/$TORID from Transmission"
        
        read -r HASH TDIR <<<$($REMOTE -t $t -i | grep -E "(Hash:|Location:)" | awk '{$1=""; print $0}' | tr '\n' ' ')
        TOR_FILE=$TOR_LOC$HASH".torrent"
        INDELUGE="${CONSOLE} ; info -v -i $HASH'"
        HASHCHECK=$(eval $INDELUGE | tail -1)

        if [ -f $TOR_FILE ] && [ -z $HASHCHECK ]; then
            
            read -p "Adding $HASH.torrent" -t 1
            echo ""
            T2DELUGE="${CONSOLE} ; add -p \"$TDIR\" \"$TOR_FILE\"'"
            eval $T2DELUGE
            
            if [[ "$VERIFY_INPUT" == "y" ]] || [[ "$VERIFY_INPUT" == "Y" ]]; then
                verify_deluge $HASH
            elif [[ "$VERIFY_INPUT" == "n" ]] || [[ "$VERIFY_INPUT" == "N" ]]; then
                sleep .1
            fi
        else
            echo "No torrent with ID: $t or hash: $HASH already exists in Deluge, skipping"
        fi
        
        # In the following line -t for timeout, -N for just 1 character
        read -t 0.25 -N 1 input
        if [[ $input = "q" ]] || [[ $input = "Q" ]]; then
            echo
            break
        fi

done

#set add_paused back to original
if [[ $ORIG_PAUSE != $PAUSEBOOL ]]; then
    echo "Reverting add_paused to original state of $ORIG_PAUSE"
    SETPAUSED="${CONSOLE} ; config -s add_paused $ORIG_PAUSE'"
    eval $SETPAUSED
fi

printf '%s completed torrent moves, more info in: %s\n' ${#arrCOMPLETE[@]} "$LOG"
printf '%s | INFO | The following HASH/IDs were successfully moved to Deluge\n' "$DT" >> "$LOG"
for VALUE in "${arrCOMPLETE[@]}"
    do
         printf '%s | SUCCESS | Completed hash: %s\n' "$DT" "$VALUE" >> "$LOG"
done

printf '%s failed torrent moves, more info in: %s\n' ${#arrFAIL[@]} "$LOG"
printf '%s | INFO | The following HASH/IDs failed to verify within Deluge and may need manual rechecks\n' "$DT" >> "$LOG"
for VALUE in "${arrFAIL[@]}"
    do
         printf '%s | ERROR | Failed hash: %s\n' "$DT" "$VALUE" >> "$LOG"
done
printf '%s | INFO | End of verification info\n' "$DT" >> "$LOG"

#check if we changed add_paused and revert if required
if [[ $ORIG_PAUSE != $PAUSEBOOL ]]; then
    echo "Reverting add_paused to original state of $ORIG_PAUSE"
    SETPAUSED="${CONSOLE} ; config -s add_paused $ORIG_PAUSE'"
    eval $SETPAUSED
fi

LINECOUNT=$(wc -l < $LOG)
if (( $(echo "$LINECOUNT > 5000"| bc -l) )); then
    echo "$(tail -5000 $LOG)" > "$LOG"
fi