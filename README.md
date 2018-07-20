# Hutspot

The app hopes to become a Spotify 'controller'. You can browse/search albums, artists, playlists and tracks. Playing is done on an 'connect' device. It requires a premium Spotify account.

Right now for authentication is done using [O2](https://github.com/pipacs/o2)
and for the API code from [spotify-web-api-js](https://github.com/JMPerez/spotify-web-api-js) is used.

O2 and spotify-web-api-js have their own license. For Hutspot it is MIT.


Hutspot is being built on [OBS](http://repo.merproject.org/obs/home:/wdehoog:/hutspot/sailfish_latest_armv7hl/).

Due to the issues below this app is not for the faint of heart. Don't use it unless you are willing to mess around.

## Issues

### Authorization
  * Logging on is problematic. It is done using a browser window. Refreshing the tokens does not seem to work as it should.
  * No idea how to close the external browser tab when O2 emits ```onCloseBrowser```
  * I honestly have no clue how this O2 is supposed to work. When to refresh what? So logging in might not work as it should.

### Playing tracks
Device discovery is problematic. Spotify does not know all your devices. The official app and application discover them using Zeroconf. Using avahi Hutspot tried the same. They are discovered but the Spotify server needs to be told they exist and I have no de how to do that. Since it is unknown how to create the needed authentication blob for a device, only the official apps seem to be able to do it, I have removed the avahi device discovery.

## Librespot on Sailfish
I managed to build and package [Librespot](https://gist.github.com/wdehoog/d83d75564ebc77a985384950af44ee7c), an open source Spotify client. A package can be downloaded from [OBS](https://api.merproject.org/package/binaries/home:wdehoog:librespot/librespot?repository=sailfishos_armv7hl). When logging in (passing credentials to librespot at startup) the Spotify server knows about it's existence for a short time so you can then select it in the device list.

Hutspot has an option in it's Settings page to start/stop Librespot.

## Operating
 
At startup authorization is done using a webview or external browser window. The tokens are saved so a next startup might not need a login. Still this webview/browser window will apear. When authorization is successful you can switch to the app.

There are some 'main' pages

 * New Releases (albums)
 * Top Stuff (artists/tracks)
 * My Stuff (albums/artists/playlists/tracks)
 * Search (albums/artists/playlists/tracks)

Opening one of these pages will clear the current Page stack
The Playing page can always be opened and will be put on top of the Page stack.

Viewing an Album/Artists/Playlist will add a new page to the stack. There is no programmed limit on the number of them.

A panel, normally hidden, contains buttons to open the various pages. The panel becomes visible when clicking on the icon next to the page header.

Various:

 * Device Page: A list is shown of known play devices. The current one is  highlighted. Using the context menu (long press) you select another device.
 * Various actions can triggered  using the context menu (long press)
 * For some lists the nex/previous set (paging) can be retrieved using the Push/Pull menus
 * The Playing page shows what is currently playing and contains various player controls.
 * Pause/Next/Previous can also be done on the Cover page or the controls on the Lock Screen.


## Thanks
 * Spotify for web api
 * JMPerez for [spotify-web-api-js](https://github.com/JMPerez/spotify-web-api-js)
 * pipacs for [O2](https://github.com/pipacs/o2)
 * fooxl and DrYak for avahi, nss-mdns and libdaemon on sailfish
 * laserpants for [qtzeroconf](https://github.com/laserpants/qtzeroconf)
 * kimmoli: IconProvider & MultiItemPicker
 * librespot-org for [Librespot](https://github.com/librespot-org/librespot)
 * dtcooper for [raspotify](https://github.com/dtcooper/raspotify)
 * sfietkonstantin for rust and cargo on OBS

