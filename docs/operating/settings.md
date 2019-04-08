---
title: Settings
parent: Operating
nav_order: 4
layout: default
---
## Settings
The Settings page allows to configure:

  * The number of results per request. Spotify seems to have a maximum of 50.
  * Number of items to save in the History list.
  * Maximum length of Sorted Lists. For lists that need to be sorted by the app all items need to be downloaded. When a lists total number of items is larger then this threshold the list is not sorted.
  * Enable Device Discovery, looking for Spotify Players on the network
  * Start Librespot when launched and stop it on exit.
  * Start Librespot or stop it.
  * Show the Devices page at startup
  * The name of the Playlist Hutspot uses when it needs to queue Tracks
  * Country code ([ISO 3166-1](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)) to be used for fetching Featured Playlists.
  * Should Spotify replace tracks in Playlists that cannot be played due to regional restrictions.
  * Delay for the Docked panel to show up again
  * Ask for confirmation of save/follow changes
  * Use cached Followed/Saved state data (only applies to Tracks for now)
  * Which menu implementation to use
  * Have the player as an attached page
  * Detect Network Connected state.
  * Use external Browser or a Webview to login at Spotify.

Application Settings are saved in ```.config/``` and can be manipulated using dconf (```dconf list /hutspot/```).


