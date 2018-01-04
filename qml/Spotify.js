/**
 * Code copied from https://github.com/JMPerez/spotify-web-api-js
 */


.pragma library

var _baseUri = 'https://api.spotify.com/v1';
var _accessToken = null;
var _username = null;

var scopes_array = [
  "streaming",
  "playlist-read-collaborative",
  "playlist-read-private",
  "user-read-recently-played",
  "user-read-private",
  "user-read-email",
  "user-modify-playback-state",
  "user-read-playback-state",
  "user-read-recently-played"
];
var _scope = scopes_array.join(" ");


//
// Request Stuff
//

function _extend() {
  var args = Array.prototype.slice.call(arguments);
  var target = args[0];
  var objects = args.slice(1);
  target = target || {};
  objects.forEach(function(object) {
    for (var j in object) {
      if (object.hasOwnProperty(j)) {
        target[j] = object[j];
      }
    }
  });
  return target;
}


function _buildUrl(url, parameters) {
  var qs = '';
  for (var key in parameters) {
    if (parameters.hasOwnProperty(key)) {
      var value = parameters[key];
      qs += encodeURIComponent(key) + '=' + encodeURIComponent(value) + '&';
    }
  }
  if (qs.length > 0) {
    // chop off last '&'
    qs = qs.substring(0, qs.length - 1);
    url = url + '?' + qs;
  }
  return url;
}

function _performRequest(requestData, callback) {
  var req = new XMLHttpRequest();
    var type = requestData.type || 'GET';
    req.open(type, _buildUrl(requestData.url, requestData.params));
    if (_accessToken) {
      req.setRequestHeader('Authorization', 'Bearer ' + _accessToken);
    }
    if (requestData.contentType) {
      req.setRequestHeader('Content-Type', requestData.contentType)
    }

    req.onreadystatechange = function() {
      if (req.readyState === 4) {
        var data = null;
        try {
          data = req.responseText ? JSON.parse(req.responseText) : '';
        } catch (e) {
          console.error(e);
        }

        if (req.status >= 200 && req.status < 300) {
          callback(data);
        } else {
          callback();
        }
      }
    }

    if (type === 'GET') {
      req.send(null);
    } else {
      var postData = null
      if (requestData.postData) {
        postData = requestData.contentType === 'image/jpeg' ? requestData.postData : JSON.stringify(requestData.postData)
      }
      req.send(postData);
    }
}

function _checkParamsAndPerformRequest(requestData, options, callback, optionsAlwaysExtendParams) {
  var opt = {};
  var cb = null;

  if (typeof options === 'object') {
    opt = options;
    cb = callback;
  } else if (typeof options === 'function') {
    cb = options;
  }

  // options extend postData, if any. Otherwise they extend parameters sent in the url
  var type = requestData.type || 'GET';
  if (type !== 'GET' && requestData.postData && !optionsAlwaysExtendParams) {
    requestData.postData = _extend(requestData.postData, opt);
  } else {
    requestData.params = _extend(requestData.params, opt);
  }
  return _performRequest(requestData, cb);
}

//
// Spotify API
//

// needs scope: user-read-playback-state
function getMyDevices(callback) {
  var requestData = {
    url: _baseUri + '/me/player/devices'
  };
  return _checkParamsAndPerformRequest(requestData, {}, callback);
}

function getUserPlaylists(userId, options, callback) {
  var requestData;
  if (typeof userId === 'string') {
    requestData = {
      url: _baseUri + '/users/' + encodeURIComponent(userId) + '/playlists'
    };
  } else {
    requestData = {
      url: _baseUri + '/me/playlists'
    };
    callback = options;
    options = userId;
  }
  return _checkParamsAndPerformRequest(requestData, options, callback);
}

