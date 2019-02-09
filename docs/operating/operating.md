---
title: Operating
nav_order: 3
layout: default
has_children: true
permalink: operating
---
## Operating

### Startup 
At startup authorization is done using a webview or external browser window. The tokens are saved so a next startup might not need a login. Still this webview/browser window might appear. When authorization is successful you can switch to the app.

### Pages
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

### Various
 * Device Page: A list is shown of known play devices. The current one is highlighted. Using the context menu (long press) you select another device.
 * Various actions can triggered using the context menu (long press).
 * For some lists the nex/previous set (paging) can be retrieved using the Push/Pull menus.
 * The Playing page shows what is currently playing and contains various player controls.
 * Pause/Next/Previous can also be done on the Cover page or the controls on the Lock Screen.
