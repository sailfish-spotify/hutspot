
.pragma library

function getDurationString(d) {
    if(typeof d === 'string' || d instanceof String) {
        // probably: hh:mm:ss.xxx
        var a = d.split(':');
        if(a.length !== 3)
            return d;
        if(parseInt(a[0])>0)
            return a[0]+":"+a[1]+":"+secondsString(Math.round(parseInt(a[2])));
        else
            return a[1]+":"+secondsString(Math.round(parseInt(a[2])));
    } else {
      // assume ms
      var s = Math.floor(d / 1000);
      var minutes = Math.floor(s / 60);
      var seconds = "0" + (s - minutes * 60);
      return minutes + ":" + seconds.substr(-2);
    }
}

function createItemsString(items, noneString) {
    if(items.length === 0)
        return noneString
    var i
    var str = ""
    for(i=0;i<items.length;i++) {
        if(i>0)
            str += ", "
        if(items[i].name)
            str += items[i].name
        else
            str += items[i]
    }
    return str
}

function getIdFromURI(uri) {
    var parts = uri.split(':');
    return parts[parts.length-1];
}

function getYearFromReleaseDate(releaseDate) {
    var parts = releaseDate.split("-")
    return parts[0]
}

function deviceInfoRequest(avahi, callback) {
  var req = new XMLHttpRequest();
    var tmp;

    // address
    var url = "http://" + avahi.ip + ":" + avahi.port;

    // path ( text also contains \s"VERSION=([^"]*)")
    if(tmp = avahi.text.match(/"CPath=([^"]*)"/))
        url += tmp[1]
    else
        url += "/"
    // request
    url += "?action=getInfo"

    req.open('GET', url);

    req.onreadystatechange = function() {
      if (req.readyState === 4) {
        var data = null;
        try {
          data = req.responseText ? JSON.parse(req.responseText) : '';
        } catch (e) {
          console.error(e);
        }

        if (req.status >= 200 && req.status < 300) {
          callback(null, data);
        } else {
          callback(data);
        }
      }
    }

    req.send(null);
}

/**
 * @type type of item
 * @ids array of ids sent to server
 * @data array of booleans returned by server
 * @model listmodel containing the items to update
 */
function setSavedInfo(type, ids, data, model) {
    var i,j,k;

    for(i=0;i<data.length;i++) {
        if(data[i]) {                        // if saved
            for(j=0;j<model.count;j++) {     // lookup in current list
                var v = model.get(j)
                if(v.type === type) {
                    var id
                    switch(type) {
                    case SpotifyItemType.Track:
                        id = v.track.id
                        break;
                    }
                    if(ids[i] === id)        // found it
                        v.saved = true
                }
            }
        }
    }
}

/**
 * @type type of item
 * @ids array of ids sent to server
 * @data array of booleans returned by server
 * @model listmodel containing the items to update
 */
function setFollowedInfo(type, ids, data, model) {
    var i,j,k;

    for(i=0;i<data.length;i++) {
        if(data[i]) {                        // if followed
            for(j=0;j<model.count;j++) {     // lookup in current list
                var v = model.get(j)
                if(v.type === type) {
                    var id
                    switch(type) {
                    case SpotifyItemType.Artist:
                        id = v.artist.id
                        break;
                    case SpotifyItemType.Playlist:
                        id = v.playlist.id
                        break
                    }
                    if(ids[i] === id)        // found it
                        v.following = true
                }
            }
        }
    }
}

Math.log10 = function (x) { return Math.log(x) / Math.LN10; };

function abbreviateNumber(number) {
    var SI_POSTFIXES = ["", "k", "M", "G", "T", "P", "E"];
    var tier = Math.log10(Math.abs(number)) / 3 | 0;
    if(tier == 0) return number;
    var postfix = SI_POSTFIXES[tier];
    var scale = Math.pow(10, tier * 3);
    var scaled = number / scale;
    var formatted = scaled.toFixed(1) + '';
    if (/\.0$/.test(formatted))
      formatted = formatted.substr(0, formatted.length - 2);
    return formatted + postfix;
}

function doesListModelContain(model, type, id) {
    var i;
    for(i=0;i<model.count;i++) {
        var obj = model.get(i);
        if(obj.type !== type)
            continue;
        var found = false;
        switch(obj.type) {
        case SpotifyItemType.Album:
            if(obj.album.id === id)
                found = true;
            break;
        case SpotifyItemType.Artist:
            if(obj.artist.id === id)
                found = true;
            break;
        case SpotifyItemType.Playlist:
            if(obj.playlist.id === id)
                found = true;
            break;
        case SpotifyItemType.Track:
            if(obj.track.id === id)
                found = true;
            break;
        }
        if(found)
            return i;
    }
    return -1;
}

function removeFromListModel(model, type, id) {
    var i = doesListModelContain(model, type, id);
    if(i<0)
        return false;
    model.remove(i);
    return true;
}

// keep in sync with Spotify.js ItemType
var SpotifyItemType = {
    Album: 0,
    Artist: 1,
    Playlist: 2,
    Track: 3
}

var HutspotMenuItem = {
    ShowAboutPage: 0,
    ShowDevicesPage: 1,
    ShowGenreMoodPage: 2,
    ShowMyStuffPage: 3,
    ShowNewReleasePage: 4,
    ShowPlayingPage: 5,
    ShowSearchPage: 6,
    ShowSettingsPage: 7,
    ShowTopStuffPage: 8
}

var HutspotPage = {
    AlbumPage: 0,
    ArtistPage: 1,
    PlaylistPage: 2,
    GenreMoodPlaylist: 3
}
