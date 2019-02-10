---
title: Operating
nav_order: 3
layout: default
has_children: true
permalink: operating
---
## Operating

### Authorization 
At startup authorization is done using a webview or external browser window. The tokens are saved so a next startup might not need a new login. Still this webview/browser window might appear. When authorization is successful you can then switch to the app.

### App Navigation
There are some 'main' pages

 * New Releases (albums)
 * My Stuff (albums/artists/playlists/tracks)
 * Top Stuff (artists/tracks)
 * Genre & Mood (categories)
 * Search (albums/artists/playlists/tracks)
 * Recommended (tracks)

Opening one of these pages will clear the current Page stack
Navigating to an Album/Artists/Playlist will add a new page to the stack. There is no programmed limit on the number of them.

The Playing page, with all the controls and the current queue is an 'attached' page of the current page.

The menu page can be openend using the 'hamburger' button or, if configured, is an attached page of the Playing page.

There are some alternative UI options. Left overs from the start of the project. They will probably be removed.

### Lists
Hutspot loads items per set using a configured number (max. 50). When there are more results available the next set will be loaded when the list is scrolled to it's end.

Various actions can triggered using the context menu (long press) of a List Item.

### Player Queue
The Spotify Web-API does not support a player queue. Therefore Hutspot uses it's own special queue playlist. This special *Queue Playlist* is used for :

 * When you want to play or queue a single track
 * When you want to play a list of recommended tracks

The name of the playlist to use can be configured in the Settings. It's default value is 'Hutspot Queue'.

### Various
 * Device Page: A list is shown of known play devices. The current one is highlighted. Using the context menu (long press) you select another device.
 * The Playing page shows what is currently playing and contains various player controls.
 * Pause/Next/Previous can also be done on the Cover page or the controls on the Lock Screen.
