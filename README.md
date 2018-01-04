# playspot
Playground for spotify stuff.

Don't expect a real app even if this is a SailfishOS one. I just try to see how things can be done using qml + cpp + javascript. 

Right now for authentication is done using https://github.com/pipacs/o2
and for the API code from https://github.com/JMPerez/spotify-web-api-js is used.

O2 and spotify-web-api-js have ther own license. For playspot it is MIT.


## Major Issues
  * No idea what needs to be done in order to play a track
  * There is no way to enumerate the devices running libspotify (raspotify) and make them play a track. For example see:

    + https://github.com/spotify/web-api/issues/540
    + https://developer.spotify.com/web-api/working-with-connect/#devices-not-appearing-on-device-list

## Minor Issues

  * No idea how to close the browser tab when O2 emits ```onCloseBrowser```


