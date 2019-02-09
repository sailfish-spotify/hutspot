---
title: Device Discovery
nav_order: 5
layout: default
---
## Device Discovery
The list of devices to play music on is managed by Spotify so Spotify needs to know the device exists. The official apps and applications discover new devices using zeroconf and some http requests. Hutspot tries do do the same and can discover connect devices on your network.

When a device is discovered still Spotify needs to be notified that device exists. This is done by sending an ```adduser`` request to the device with encrypted info (authorization blob). The the device will register itself at the Spotify servers. Librespot can store and reuse your credentials (see [Librespot](/librespot)) and these stored credentials can be used by Hutspot to create such a request. 

On success the device appears in the list provided by Spotify and then it can be selected as your current device. 

#### Notes: 
 * It is a bit flaky so it can require some list refreshing and retries.
 * This is currently only tested with devices running Librespot (raspberry pi and banana pi).

