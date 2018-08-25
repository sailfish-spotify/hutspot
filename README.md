# Hutspot

The app hopes to become a Spotify 'controller'. You can browse/search albums, artists, playlists and tracks. Playing is done on an 'connect' device. It requires a premium Spotify account.

Right now for authentication is done using [O2](https://github.com/pipacs/o2)
and for the API code from [spotify-web-api-js](https://github.com/JMPerez/spotify-web-api-js) is used.

O2 and spotify-web-api-js have their own license. For Hutspot it is MIT.


Hutspot is being built on [OBS](http://repo.merproject.org/obs/home:/wdehoog:/hutspot/sailfish_latest_armv7hl/). See [this wiki page](https://github.com/sailfish-spotify/hutspot/wiki/Installation) on how to install it.

Due to the issues with detecting Spotify capable players this app is not 'plug and play'. Don't use it unless you are willing to mess around.


### Playing tracks
Device discovery is problematic. Spotify does not know all your devices. The official app and application discover them using Zeroconf. Using avahi Hutspot tried the same. They are discovered but the Spotify server needs to be told they exist and I have no de how to do that. Since it is unknown how to create the needed authentication blob for a device, only the official apps seem to be able to do it, I have removed the avahi device discovery.

### Librespot on Sailfish
I managed to build and package [Librespot](https://github.com/librespot-org/), an open source Spotify client. A package can be downloaded from [OBS](https://api.merproject.org/package/binaries/home:wdehoog:librespot/librespot?repository=sailfishos_armv7hl). 

For more see the wiki page on [Librespot](https://github.com/sailfish-spotify/hutspot/wiki/Librespot)

Hutspot has an option in it's Settings page to start/stop the Librespot service.

### Operating
 
See the wiki page on [Operating](https://github.com/sailfish-spotify/hutspot/wiki/Operating)

### Donations
Sorry but we do not accept any donations. We do appreciate the gesture but it is a hobby that we are able to do because others are investing their time as well.

If someone wants to show appreciation for our work by a donation then we suggest to help support openrepos.net.

### Thanks
 * Spotify for web api
 * JMPerez for [spotify-web-api-js](https://github.com/JMPerez/spotify-web-api-js)
 * pipacs for [O2](https://github.com/pipacs/o2)
 * fooxl and DrYak for avahi, nss-mdns and libdaemon on sailfish
 * laserpants for [qtzeroconf](https://github.com/laserpants/qtzeroconf)
 * kimmoli: IconProvider & MultiItemPicker
 * leszek: DevicePixelRatioHack
 * librespot-org for [Librespot](https://github.com/librespot-org/librespot)
 * dtcooper for [raspotify](https://github.com/dtcooper/raspotify)
 * sfietkonstantin for rust and cargo on OBS

