# playspot
Playground for spotify stuff.

The app is a Spotify 'controller'. You can browse/search albums, artists, playlists and tracks. Playing is done on an 'connect' device.

Right now for authentication is done using https://github.com/pipacs/o2
and for the API code from https://github.com/JMPerez/spotify-web-api-js is used.

O2 and spotify-web-api-js have ther own license. For playspot it is MIT.


## Issues
  * Logging on is problematic. It is done using a browser window. Refreshing the tokens does not work as it should.
  * Device discovery is problematic. 
  * I managed to [build Librespot](https://gist.github.com/wdehoog/d83d75564ebc77a985384950af44ee7c) and it even sometimes occurs on the list of devices so it can be used to play tracks. 
  * No idea how to close the browser tab when O2 emits ```onCloseBrowser```


