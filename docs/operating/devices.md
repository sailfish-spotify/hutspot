---
title: Devices Page
parent: Operating
nav_order: 6
layout: default
---
## Devices Page

### Detection
The Devices Page shows the list of known 'Connect' devices. There are two categories:

 * Known to Spotify. These can be selected as Current Device. They are shown in normal colors.
 * Detected on the network but unknown to Spotify. They are shown a bit more transparent then the others.

When a device is detected but not yet known to Spotify it can register itself (at Spotify). This is triggered by the context menu option 'Connect using Authorization Blob'.

The list of devices know to Spotify is refreshed every 2s. The discovered devices are added/removed as as soon as their presence is detected.

*Note:* this has only been tested with Librespot instances. Please do tell us what happens with other kinds of devices.

### Librespot
If configured to do so Hutspot tries to make the Librespot instance on the phone it's current one. First if needed it is started, then it is waiting for Librespot to appear in Spotify's list of known devices, then if it does appear it is selected as the current one.

Unfortunately a lot of things can go wrong so it might take some time before all is well. Sometimes it helps to stop/start Librespot (see Settings Page).


