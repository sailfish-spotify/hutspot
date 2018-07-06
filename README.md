# hutspot

The app hopes to become a Spotify 'controller'. You can browse/search albums, artists, playlists and tracks. Playing is done on an 'connect' device.

Right now for authentication is done using [O2](https://github.com/pipacs/o2)
and for the API code from [spotify-web-api-js](https://github.com/JMPerez/spotify-web-api-js) is used.

O2 and spotify-web-api-js have their own license. For playspot it is MIT.

Currently you also need avahi. I have build it on [OBS](http://repo.merproject.org/obs/home:/wdehoog:/hutspot/sailfish_latest_armv7hl/).

Due to the issues below this app is not for the faint of heart. Don't use it unless you are willing to mess around.

## Issues

### Authorization
  * Logging on is problematic. It is done using a browser window. Refreshing the tokens does not work as it should.
  * No idea how to close the browser tab when O2 emits ```onCloseBrowser```
  * I honestly have no clue how this O2 is supposed to work. When to refresh what?

### Playing
  * Device discovery is problematic. Spotify does not know all your devices. The official app and application discover them using Zeroconf. Using avahi playspot tries the same. They are discovered but the Spotify server needs to be told they exist and I have no de how to do that.
  * I managed to [build Librespot](https://gist.github.com/wdehoog/d83d75564ebc77a985384950af44ee7c) and it even sometimes occurs on the list of devices so it can be used to play tracks. When logging in (passing credentials to librespot at startup) the Spotify server knows about it for a short time.

## Building
I am currently building it on Sailfish SDK.

You need libavahi-devel:
```
sb2 -t SailfishOS-2.2.0.29-armv7hl -m sdk-install -R ssu ar hutspot http://repo.merproject.org/obs/home:/wdehoog:/hutspot/sailfish_latest_armv7hl
sb2 -t SailfishOS-2.2.0.29-armv7hl -m sdk-install -R zypper ref
sb2 -t SailfishOS-2.2.0.29-armv7hl -m sdk-install -R zypper in libavahi-devel
```

## Thanks
 * Spotify for web api
 * JMPerez for [spotify-web-api-js](https://github.com/JMPerez/spotify-web-api-js)
 * pipacs for [O2](https://github.com/pipacs/o2)
 * fooxl and DrYak for avahi, nss-mdns and libdaemon on sailfish
 * laserpants for [qtzeroconf](https://github.com/laserpants/qtzeroconf)

