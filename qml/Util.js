
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

function getCursorsInfo(cursors) {
    var maxTotal = 0
    var offset = 0
    var canNext = false
    var canPrevious = false
    var hasNext = false
    var hasPrevious = false
    var hasBefore = false
    var hasAfter = false
    var before = 0
    var after = 0
    for(var i=0;i<cursors.length;i++) {
        if(cursors[i] === undefined)
            continue
        if(cursors[i].total > maxTotal)
            maxTotal = cursors[i].total
        if(cursors[i].offset !== 0)
            offset = cursors[i].offset // ToDo: they will probably all be the same
        if(cursors[i].canNext)
            canNext = true
        if(cursors[i].canPrevious)
            canPrevious = true
        if(cursors[i].hasNext)
            hasNext = true
        if(cursors[i].hasPrevious)
            hasPrevious = true
        if(cursors[i].hasBefore)
            hasBefore = true
        if(cursors[i].hasAfter)
            hasAfter = true
        if(cursors[i].cursors && cursors[i].cursors.after)
            after = cursors[i].cursors.after
        if(cursors[i].cursors && cursors[i].cursors.before)
            before = cursors[i].cursors.before
    }
    return {offset: offset, maxTotal: maxTotal,
            canPrevious: canPrevious, canNext: canNext,
            hasPrevious: hasPrevious, hasNext: hasNext,
            before: before, after: after,
            hasBefore: hasBefore, hasAfter: hasAfter}
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
    ShowRecommendedPage: 10
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
