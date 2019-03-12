
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
    var sb = new Classes.StringBuilder()
    for(i=0;i<items.length;i++) {
        if(items[i].name)
            sb.append(items[i].name)
        else
            sb.append(items[i])
    }
    return sb.toString(" & ")
}

function getIdFromURI(uri) {
    var parts = uri.split(':');
    return parts[parts.length-1];
}

function getYearFromReleaseDate(releaseDate) {
    var parts = releaseDate.split("-")
    return parts[0]
}

function getPlayedAtText(playedAt) {
    // "played_at": "2016-12-13T20:44:04.589Z"
    //var date = new Date(playedAt)
    //return date.toLocaleDateString()
    return playedAt.split('T')[0]
}

function getAddedAtText(addedAt) {
    return addedAt.split('T')[0]
}

function deviceAddUserRequest(device, userData, callback) {
    var req = new XMLHttpRequest();
    var url = "http://" + device.ip + ":" + device.port;
    if(device.CPath.length > 0)
        url += device.CPath;
    else
        url += "/";
    url += "?action=addUser"
    req.open('POST', url);
    req.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
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
    var content = ""
    var firstDone = false
    for(var key in userData) {
        if(userData.hasOwnProperty(key)) {
            var value = userData[key];
            if(firstDone)
                content += "&";
            content += encodeURIComponent(key) + '=' + encodeURIComponent(value);
            firstDone = true
        }
    }
    req.send(content);
}

function deviceInfoRequestMDNS(mdns, callback) {
    var req = new XMLHttpRequest();
    var tmp;

    // address
    var url = "http://" + mdns.ip + ":" + mdns.port;

    // path ( text also contains \s"VERSION=([^"]*)")
    if(mdns.CPath.length > 0)
        url += mdns.CPath
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
                        id = v.item.id
                        break;
                    }
                    if(ids[i] === id)        // found it
                        v.saved = true
                }
            }
        }
    }
}

function setFollowedInfo(id, following, model) {
    var i
    for(i=0;i<model.count;i++) {
        var v = model.get(i)
        if(v.item.id === id) {
            v.following = following
            break
        }
    }
}

function updateFollowingSaved(spotifyDataCache, model) {
    var i
    for(i=0;i<model.count;i++) {
        var obj = model.get(i)
        switch(obj.type) {
        case SpotifyItemType.Album:
            obj.saved = spotifyDataCache.isAlbumSaved(obj.item.id)
            break
        case SpotifyItemType.Artist:
            obj.following = spotifyDataCache.isArtistFollowed(obj.item.id)
            break
        case SpotifyItemType.Playlist:
            obj.following = spotifyDataCache.isPlaylistFollowed(obj.item.id)
            break
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

function createPageHeaderLabel(s0, s1, theme) {
    return "<font color=\"" + theme.primaryColor.toString() + "\">"
           + s0 + "</font>"
           + "<font color=\"" + theme.highlightColor.toString() + "\">"
           + s1 + "</font>"
}

function isTrackPlayable(track) {
    if(track && typeof track.is_playable !== "undefined") {
        if(!track.is_playable)
            return false
    } else if(track && typeof track.available_markets !== "undefined") {
        if(track.available_markets.length === 0)
            return false
    }
    return true
}

function doesListModelContain(model, type, id) {
    var i;
    for(i=0;i<model.count;i++) {
        var obj = model.get(i);
        if(obj.type !== type)
            continue;
        if(obj.item.id === id)
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

function startsWith(str, start) {
    return str.match("^"+start) !== null;
}

function parseSpotifyUri(uri) {
    // "spotify:artist:2BQWHuvxG4kMYnfghdaCIy"
    // "​spotify:​album:​2XhuJQah9yLvEBZCSBKh0q"​
    // "spotify:playlist:37i9dQZF1DZ06evO3OC4Te"               coming api
    // "spotify:user:ukfmusic:playlist:0Zarq4BVkFkZOWkmqsfrjA" current api
    var parsed = {type: undefined}
    if(startsWith(uri, "spotify:")) {
        var typeStr = uri.slice(8)
        if(startsWith(typeStr, "album:"))
            parsed.type = SpotifyItemType.Album
        else if(startsWith(typeStr, "artist:"))
            parsed.type = SpotifyItemType.Artist
        else if(startsWith(typeStr, "playlist:")
                || startsWith(typeStr, "user:"))
            parsed.type = SpotifyItemType.Playlist
    }
    parsed.id = uri.slice(uri.lastIndexOf(":")+1)
    return parsed
}

function updateSearchHistory(searchString, search_history, maxSize) {
    if(!searchString || searchString.length === 0)
        return

    var sh = search_history.value
    var pos = sh.indexOf(searchString)
    if(pos > -1) {
        // already in the list so reorder
        for(var i=pos;i>0;i--)
            sh[i] = sh[i-1]
        sh[0] = searchString
    } else
        // a new item
        sh.unshift(searchString)

    while(sh.length > maxSize)
        sh.pop()

    search_history.value = sh
}

function processSearchString(searchString) {
    // if no wildcard present and no dash and no quote
    // we add a wildcard at the end
    var canAdd = true
    var symbols = "*-'\""
    for(var i=0;i<symbols.length;i++) {
        var pos = searchString.indexOf(symbols[i])
        if(pos >= 0) {
            canAdd = false
            break
        }
    }
    if(canAdd)
        searchString = searchString + '*'
    return searchString
}

function getFirstCharForSection(str) {
    var c = str[0]
    if (c >= '0' && c <= '9')
        return "#"
    return c
}

var CursorType = {
  Normal: 0,
  FollowedArtists: 1,
  RecentlyPlayed: 2
};

function loadCursor(data, cursorType) {
    var tmp
    var cursor = {}

    cursor.type = CursorType.Normal
    if(cursorType)
        cursor.type = cursorType

    cursor.limit = data.limit ? data.limit : -1
    cursor.offset = data.offset ? data.offset : 0
    cursor.total = data.total ? data.total : -1

    cursor.next_offset = -1
    cursor.next_limit = -1
    if(data.next) {
        if(tmp = data.next.match(/offset=(\d+)/))
            cursor.next_offset = parseInt(tmp[1], 10)
        if(tmp = data.next.match(/limit=(\d+)+/))
            cursor.next_limit = parseInt(tmp[1], 10)
    }

    cursor.previous_offset = -1
    cursor.previous_limit = -1
    if(data.previous) {
        if(tmp = data.previous.match(/offset=(\d+)/))
            cursor.previous_offset = parseInt(tmp[1], 10)
        if(tmp = data.previous.match(/limit=(\d+)+/))
            cursor.previous_limit = parseInt(tmp[1], 10)
    }

    cursor.hasBefore = false
    cursor.hasAfter = false

    // recently played cursor has a before- or after time
    //   "cursors": { "after": "1481661844589", "before": "1481661737016"}
    cursor.cursors = undefined
    if(cursorType
       && cursorType === CursorType.RecentlyPlayed
       && data.cursors) {
        var cursors = {}
        if(data.cursors.before) {
            cursors.before = parseInt(data.cursors.before, 10)
            cursor.hasBefore = true
        }
        if(data.cursors.after) {
            cursors.after = parseInt(data.cursors.after, 10)
            cursor.hasAfter = true
        }
        cursor.cursors = cursors
    }

    // cursor of following artists has an 'after' artist id
    if(cursorType
       && cursorType === CursorType.FollowedArtists
       && data.cursors) {
      cursor.cursors = data.cursors
      cursor.hasAfter = data.cursors.after
    }

    // are prev/next queries provided or the cursors
    cursor.hasNext = (data.next && data.next !== null)
                     || (cursor.hasAfter)
    cursor.hasPrevious = (data.previous && data.previous !== null)
                          || (cursor.hasBefore)

    return cursor
}

/*function getNextCursorText(offset, limit, total) {
    var lower = offset + limit
    var upper = lower + limit
    if(upper > total)
        upper = total
    return "(" + lower + ".." + upper + "/" + abbreviateNumber(total) + ")"
}

function getPreviousCursorText(offset, limit, total) {
    var lower = offset - limit
    if(lower < 0)
        lower = 0
    var upper = lower + limit
    return "(" + lower + ".." + upper + "/" + abbreviateNumber(total) + ")"
}*/


var Classes = {
    StringBuilder : function() {
        var strings = [];
        this.append = function(value) {
            strings.push(value);
        }
        this.clear = function() {
            strings.length = 0
        }
        this.toString = function(separator) {
            return strings.join(separator);
        }
    }
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
    ShowTopStuffPage: 8,
    ShowHistoryPage: 9,
    ShowRecommendedPage: 10,
    ShowHelp: 11
}

var HutspotPage = {
    Album: 0,
    Artist: 1,
    Playlist: 2,
    GenreMoodPlaylist: 3
}

var PlaylistEventType = {
    AddedTrack: 0,
    RemovedTrack: 1,
    ReplacedAllTracks: 2,
    ChangedDetails: 3,
    CreatedPlaylist: 4
}

function PlayListEvent(type, playlistId, snapshotId) {
    this.type = type
    this.playlistId = playlistId
    this.snapshotId = snapshotId
}

function FavoriteEvent(type, id, uri, isFavorite) {
    this.type = type
    this.id = id
    this.uri = uri
    this.isFavorite = isFavorite    
}

function hasDeviceChanged(device0, device1) {
    if(device0.id !== device1.id)
        return true
    if(device0.is_active !== device1.is_active)
        return true
    if(device0.is_private_session !== device1.is_private_session)
        return true
    if(device0.is_restricted !== device1.is_restricted)
        return true
    if(device0.name !== device1.name)
        return true
    if(device0.type !== device1.type)
        return true
    if(device0.volume_percent !== device1.volume_percent)
        return true
    return false
}

var NetworkState = {
    Unknown: 1,
    Connected: 2,
    Disconnected: 3
}
