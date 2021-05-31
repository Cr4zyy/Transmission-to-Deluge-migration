# Transmission-to-Deluge-migration
Move torrents from Transmission to Deluge

======
**Transmission 2 Deluge** allows you to move your torrents from Transmission to Deluge with correct data locations and verification.

## Setup

* Change the USER:PASS to your USERNAME and PASSWORD for your transmission-remote and deluge-console
* Change THOME to the user that transmission runs as, because it uses the .config folder to find the current torrent.
* The script will promt you if you wish to run with data verification enabled or not as the script completes verification of the added torrent before adding the next, this can take a long time.
* With verification disabled the script will add the torrents to Deluge and you can mass re-check them as you wish.
* You can start and stop the script and re-run it any torrent in transmission that is also in deluge will be skipped
* 
* BASH script

Hope it works.
