# playspot
Playground for spotify stuff.

Don't expect a real app even if this is a SailfishOS one. I just try to see how things can be done using qml + cpp + javascript. 

Right now for authentication is done using https://github.com/pipacs/o2
and for the API code from https://github.com/JMPerez/spotify-web-api-js is used.

O2 and spotify-web-api-js have ther own license. For playspot it is MIT.


## Issues
  * No idea what needs to be done in order to play a track in a Qt player.
  * I managed to [build Librespot](https://gist.github.com/wdehoog/d83d75564ebc77a985384950af44ee7c) and it even sometimes occurs on the list of devices so it can be used to play tracks. 
  * No idea how to close the browser tab when O2 emits ```onCloseBrowser```


