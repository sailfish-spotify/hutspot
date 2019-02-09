---
title: Device Discovery
nav_order: 5
layout: default
---
The list of devices to play music on is managed by Spotify (see web-api /me/player/devices) so Spotify needs to know the device exists.

The official apps and applications discover new devices using zeroconf and some http requests. Hutspot tries do do the same and can discover connect devices on your network.

When a device is discovered by Hutspot still Spotify needs to be notified the device exists. This is done by sending encrypted info (authorization blob) to the Spotify servers by that device. Librespot can store and reuse your credentials (see [Librespot](/librespot)) and these can be used by Hutspot to register other connect devices as well. On success the device appears in the list provided by the Spotify Web-API. Note that it is a bit flaky so it can require some list refreshing and retries.

This is currently only tested with devices running Librespot (raspberry pi and banana pi).

