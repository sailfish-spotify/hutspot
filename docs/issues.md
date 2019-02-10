---
title: Issues
nav_order: 6
layout: default
---
## Issues

Please report any problems or requests in the [Github Issue Tracker](https://github.com/sailfish-spotify/hutspot/issues)

#### Playlist Snapshots
When you play a playlist you are in fact playing a specific snapshot of that playlist. This means that any modification to that playlist will not be reflected in the list being Played. For example added tracks will not show up until the playlist is restarted.

As Hutspot uses a playlist for playing seperate tracks this is a problem. Currently Hutspot, when reaching the end of the last track, tries to determine if the playlist has been modified and then to load the fresh snapshot and continue with the new tracks. Unfortunately this is not working correctly.