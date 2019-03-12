---
title: Introduction
nav_order: 1
layout: default
---
#  Welcome to the Hutspot Documentation
Hutspot is a Spotify controller for Sailfish-OS. It uses the [Spotify web-api](https://developer.spotify.com/documentation/web-api/). Playing is done on an 'connect' device. It requires a premium Spotify account. 

Main features:

 * Browse Albums/Artists/Playlists
 * Search Albums/Artists/Playlists/Tracks
 * Support for Genres & Moods, New Releases, Featured Playlists and Recommendations
 * Follow/Unfollow, Save/Unsave
 * Discover and control Connect Devices
 * Control Play/Pause/Next/Previous/Volume/Shuffle/Replay/Seek
 * Create and Edit Playlists
 * Supports local Librespot service
 * Supports Mpris and Media Keys

It does not support saving tracks nor offline playing

### Librespot on Sailfish
Playing music on your phone can be done using [Librespot](https://github.com/librespot-org/), an open source Spotify player. 
Hutspot has some options in it's Settings page to integrate the Librespot service. For example Start/Stop and Register Credentials.

### Development
Sources of Hutspot can be found on [github](https://github.com/sailfish-spotify/hutspot).
Development is done using the Sailfish OS IDE. Most sources are QML and Javascript. Some part is done in C++.

Please report any problems or requests in the [Github Issue Tracker](https://github.com/sailfish-spotify/hutspot/issues)

### Translations

Translations are welcome. Either through a Pull-Request or using [Transifex](https://www.transifex.com/sailfish-spotify/hutspot/dashboard/).

Current translations:

  * Chinese (zh)
  * Finnish (fi)
  * German (de)
  * Italian (it)
  * Swedish (sv)

### Thanks
 * Spotify for web api
 * JMPerez for [spotify-web-api-js](https://github.com/JMPerez/spotify-web-api-js)
 * pipacs for [O2](https://github.com/pipacs/o2)
 * Nathan Osman: [qmdnsengine](https://github.com/nitroshare/qmdnsengine)
 * kimmoli: IconProvider & MultiItemPicker
 * leszek: DevicePixelRatioHack
 * librespot-org for [Librespot](https://github.com/librespot-org/librespot)
 * dtcooper for [raspotify](https://github.com/dtcooper/raspotify)
 * sfietkonstantin for rust and cargo on OBS

### License
O2 and spotify-web-api-js have their own license. For Hutspot it is MIT.

Hutspot is being built on [OBS](http://repo.merproject.org/obs/home:/wdehoog:/hutspot/sailfish_latest_armv7hl/). See [Installation](/installation) on how to install it.

Due to the issues with detecting Spotify capable players this app is not 'plug and play'. Don't use it unless you are willing to mess around.

### Donations
Sorry but we do not accept any donations. We do appreciate the gesture but it is a hobby that we are able to do because others are investing their time as well.

If someone wants to show appreciation for our work by a donation then we suggest to help support openrepos.net.

