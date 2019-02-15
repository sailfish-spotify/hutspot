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
    property var _savedAlbumsId: ({})   //  key is id, stores uri

    function isPlaylistFollowed(id) {
        return _followedPlaylistsId.find(id) !== null
    }

    function isArtistFollowed(id) {
        return _followedArtistsId.find(id) !== null
    }

    function isAlbumSaved(id) {
        return _savedAlbumsId.find(id) !== null
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
                else {
                    app.doBeforeStart.notifyHappend(app.doBeforeStart.followedPlaylistsMask)
                    console.log("Loaded info of " + _followedPlaylistsId.items.length + " followed playlists")
                }
            }
        })
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
                else {
                    app.doBeforeStart.notifyHappend(app.doBeforeStart.followedArtistsMask)
                    console.log("Loaded info of " + _followedArtistsId.items.length + " followed artists")
                }
            }
        })
    }

    // Saved Albums
    function loadSavedAlbums() {
        _savedAlbumsId = new BSALib.BSArray()
        _loadSavedAlbums(0)
    }

    function _loadSavedAlbums(offset) {
        Spotify.getMySavedAlbums({offset: offset, limit: 50}, function(error, data) {
            var i
            if(data && data.items) {
                for(i=0;i<data.items.length;i++) {
                    _savedAlbumsId.insert(
                        data.items[i].album.id, data.items[i].album.uri)
                }
                var nextOffset = data.offset+data.items.length
                if(nextOffset < data.total)
                    _loadSavedAlbums(nextOffset)
                else {
                    app.doBeforeStart.notifyHappend(app.doBeforeStart.savedAlbumsMask)
                    console.log("Loaded info of " + _savedAlbumsId.items.length + " saved albums")
                }
            }
        })
    }

    Connections {
        target: app

        onIdChanged: {
            if(app.id !== "") {
                loadFollowedPlaylists()
                loadFollowedArtists()
                loadSavedAlbums()
            }
        }

        onFavoriteEvent: {
            switch(event.type) {
            case Util.SpotifyItemType.Album:
                if(event.isFavorite)
                    _savedAlbumsId.insert(event.id, event.uri)
                else
                    _savedAlbumsId.remove(event.id)
                break
            case Util.SpotifyItemType.Artist:
                if(event.isFavorite)
                    _followedArtistsId.insert(event.id, event.uri)
                else
                    _followedArtistsId.remove(event.id)
                break
            case Util.SpotifyItemType.Playlist:
                if(event.isFavorite)
                    _followedPlaylistsId.insert(event.id, event.uri)
                else
                    _followedPlaylistsId.remove(event.id)
                break
            }
        }
    }

}
