/**
 * Hutspot.
 * Copyright (C) 2019 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

import "../Spotify.js" as Spotify
import "../Util.js" as Util
import "../BSArray.js" as BSALib


Item {

    property var _followedPlaylistsId: ({})   //  key is id, stores uri
    //property var _followedPlaylistsName: ({}) // key is name, stores id

    property var _followedArtistsId: ({})   //  key is id, stores uri

    function isPlaylistFollowed(id) {
        return _followedPlaylistsId.find(id) !== null
    }

    function isArtistFollowed(id) {
        return _followedArtistsId.find(id) !== null
    }

    // Followed Playlists
    function loadFollowedPlaylists() {
        _followedPlaylistsId = new BSALib.BSArray()
        //_followedPlaylistsName = new BSALib.BSArray()
        _loadFollowedPlaylistsSet(0)
    }

    function _loadFollowedPlaylistsSet(offset) {
        Spotify.getUserPlaylists(app.id, {offset: offset, limit: 50}, function(error, data) {
            var i
            if(data && data.items) {
                for(i=0;i<data.items.length;i++) {
                    _followedPlaylistsId.insert(
                        data.items[i].id, data.items[i].uri)
                    //_followedPlaylistsName.insert(
                    //    data.items[i].name, data.items[i].id)
                }
                var nextOffset = data.offset+data.items.length
                if(nextOffset < data.total)
                    _loadFollowedPlaylistsSet(nextOffset)
                else
                    console.log("Loaded info on " + _followedPlaylistsId.items.length + " followed playlists")
            }
        })
    }

    function notifyFollowPlaylist(id, uri) {
        _followedPlaylistsId.insert(id, uri)
    }

    function notifyUnfollowPlaylist(id) {
        _followedPlaylistsId.remove(id)
    }

    // Followed Artists
    function loadFollowedArtists() {
        _followedArtistsId = new BSALib.BSArray()
        _loadFollowedArtists(0)
    }

    function _loadFollowedArtists(offset) {
        Spotify.getFollowedArtists({offset: offset, limit: 50}, function(error, data) {
            var i
            if(data && data.artists) {
                for(i=0;i<data.artists.items.length;i++) {
                    _followedArtistsId.insert(
                        data.artists.items[i].id, data.artists.items[i].uri)
                }
                var nextOffset = data.offset+data.artists.items.length
                if(nextOffset < data.artists.total)
                    _loadFollowedPlaylistsSet(nextOffset)
                else
                    console.log("Loaded info on " + _followedArtistsId.items.length + " followed artists")
            }
        })
    }

    function notifyFollowArtist(id, uri) {
        _followedArtistsId.insert(id, uri)
    }

    function notifyUnfollowArtist(id, uri) {
        _followedArtistsId.remove(id)
    }

    Connections {
        target: app
        onIdChanged: {
            if(app.id !== "") {
                loadFollowedPlaylists()
                loadFollowedArtists()
            }
        }
    }

}
