apt-get update && apt-get --yes install sudo wget unzip mc
wget -q -O - http://apt.mopidy.com/mopidy.gpg | sudo apt-key add -
wget -q -O /etc/apt/sources.list.d/mopidy.list http://apt.mopidy.com/mopidy.list
apt-key adv --keyserver pool.sks-keyservers.net --recv 32D9C2A835ED066C
apt-key adv --keyserver pool.sks-keyservers.net --recv 7808CE96D38B9201
cat << EOF > /etc/apt/sources.list.d/upmpdcli.list
deb http://www.lesbonscomptes.com/upmpdcli/downloads/raspbian-wheezy/ unstable main
deb-src http://www.lesbonscomptes.com/upmpdcli/downloads/raspbian-wheezy/ unstable main
EOF

sudo apt-get update && sudo apt-get --yes --no-install-suggests --no-install-recommends install youtubedl logrotate alsa-utils wpasupplicant gstreamer1.0-alsa ifplugd gstreamer1.0-fluendo-mp3 gstreamer1.0-tools samba dos2unix avahi-utils alsa-base cifs-utils avahi-autoipd libnss-mdns ntpdate ca-certificates ncmpcpp rpi-update alsa-firmware-loaders firmware-brcm80211 firmware-linux firmware-linux-nonfree iptables build-essential python-dev python-pip python-gst-1.0 gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly usbmount monit upmpdcli watchdog dropbear mpc dosfstools
chmod u+s /sbin/shutdown

#Let everyone shutdown the system (to support it from the webclient):
chmod u+s /sbin/shutdown

#**Add the mopidy user**
#Mopidy runs under the user mopidy. Add it.
useradd -m mopidy
passwd -l mopidy

#Add the user to the group audio:
usermod -a -G audio mopidy

#Create a couple of directories inside the user dir:
mkdir -p /var/lib/mopidy
mkdir -p /var/cache/mopidy
mkdir -p /var/log/mopidy
chown -R mopidy:mopidy /home/mopidy

#**Create Music directory for MP3/OGG/FLAC **
#Create the directory containing the music and the one where the network share is mounted:
mkdir -p /music/MusicBox
mkdir -p /music/Network
mkdir -p /music/playlists
chmod -R 777 /music
chown -R mopidy:mopidy /music


SHAIRPORT_BUILD_DEPS="build-essential xmltoman autoconf automake libdaemon-dev libasound2-dev libpopt-dev libconfig-dev libavahi-client-dev libssl-dev"
SHAIRPORT_RUN_DEPS="libc6 libconfig9 libdaemon0 libasound2 libpopt0 libavahi-common3 avahi-daemon libavahi-client3 libssl1.0.0 libtool avahi-daemon"
apt-get install --yes $SHAIRPORT_BUILD_DEPS $SHAIRPORT_RUN_DEPS


wget https://github.com/mikebrady/shairport-sync/archive/3.0.2.zip
unzip 3.0.2.zip && rm 3.0.2.zip
pushd shairport-sync-3.0.2
autoreconf -i -f
./configure --sysconfdir=/etc --with-alsa --with-avahi --with-ssl=openssl --with-metadata --with-systemv
make && make install
popd
rm -rf shairport-sync*



mkdir -p /opt/librespot
pushd /opt/librespot
wget https://github.com/herrernst/librespot/releases/download/v20170717-910974e/librespot-linux-armhf-raspberry_pi.zip
unzip librespot-linux-armhf-raspberry_pi.zip
rm librespot-linux-armhf-raspberry_pi.zip
popd

wget https://github.com/pimusicbox/mpd-watchdog/releases/download/v0.3.0/mpd-watchdog_0.3.0-0tkem2_all.deb
dpkg -i mpd-watchdog_0.3.0-0tkem2_all.deb
rm mpd-watchdog_0.3.0-0tkem2_all.deb

PYTHON_BUILD_DEPS="build-essential python-dev libffi-dev libssl-dev"
apt-get install --yes $PYTHON_BUILD_DEPS
sudo apt-get install python-gst-1.0 gir1.2-gstreamer-1.0 gir1.2-gst-plugins-base-1.0 gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-tools

rm -rf /tmp/pip_build_root
python -m pip install -U pip
# Upgrade some dependencies.
pip install --upgrade requests[security] backports.ssl-match-hostname backports-abc tornado gmusicapi pykka pylast pafy youtube-dl

pip install mopidy
pip install mopidy-musicbox-webclient
pip install mopidy-websettings
pip install mopidy-mopify
pip install mopidy-mobile
pip install mopidy-youtube
pip install mopidy-gmusic
pip install mopidy-spotify-web
pip install mopidy-spotify-tunigo
pip install mopidy-spotify
pip install mopidy-tunein
pip install mopidy-local-sqlite
pip install mopidy-scrobbler
pip install mopidy-soundcloud
pip install mopidy-dirble
pip install mopidy-podcast
pip install mopidy-podcast-itunes
pip install mopidy-internetarchive
pip install Mopidy-API-Explorer
pip install Mopidy-Iris

# Speedup MPD connections.
sed -i '/try:/i \
        # Horrible hack here:\
        core.library\
        core.history\
        core.mixer\
        core.playback\
        core.playlists\
        core.tracklist' /usr/local/lib/python2.7/dist-packages/mopidy/mpd/actor.py
# Force YouTube to favour m4a streams as gstreamer0.10's webm support is bad/non-existent:
sed -i '/getbestaudio(/getbestaudio(preftype="m4a"/' /usr/local/lib/python2.7/dist-packages/mopidy_youtube/backend.py
# Hide broken Spotify Web 'Genres & Moods' and 'Featured Playlists' browsing:
sed -i '222,+3 s/^/#/' /usr/local/lib/python2.7/dist-packages/mopidy_spotify_web/library.py
sed -i '222i ]' /usr/local/lib/python2.7/dist-packages/mopidy_spotify_web/library.py
# Hide broken Spotify Tunigo 'Genres & Moods', 'Featured Playlists' and 'Top Lists' browsing:
sed -i '27,+8 s/^/#/' /usr/local/lib/python2.7/dist-packages/mopidy_spotify_tunigo/library.py
# Hide broken Spotify browsing entirely:
sed -i '/root_directory = / s/^/#/' /usr/local/lib/python2.7/dist-packages/mopidy_spotify/library.py

deluser --remove-home mopidy
adduser --quiet --system --no-create-home --home /var/lib/mopidy --ingroup audio mopidy
chown -R mopidy:audio /var/cache/mopidy
chown -R mopidy:audio /var/lib/mopidy
chown -R mopidy:audio /var/log/mopidy
chown -R mopidy:audio /music/playlists

MUSICBOX_SERVICES="ssh dropbear upmpdcli shairport-sync mpd-watchdog"
for service in $MUSICBOX_SERVICES
do
    update-rc.d $service disable
done

apt-get install --yes git rpi-update

SKIP_WARNING=1 rpi-update

