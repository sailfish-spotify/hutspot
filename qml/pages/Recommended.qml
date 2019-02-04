/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.2
import Sailfish.Silica 1.0

import "../components"
import "../Spotify.js" as Spotify
import "../Util.js" as Util

Page {
    id: recommendatedPage
    objectName: "RecommendatedPage"

    property bool showBusy: false

    property int currentIndex: -1
    property var genreSeeds: []

    // 0 for seeds, 1 for attributes
    property int recommendationMode: 0

    allowedOrientations: Orientation.All

    ListModel {
        id: searchModel
    }

    SilicaListView {
        id: listView
        model: searchModel

        width: parent.width
        anchors.top: parent.top
        height: parent.height - app.dockedPanel.visibleSize
        clip: app.dockedPanel.expanded

        PullDownMenu {
            MenuItem {
                text: qsTr("Reload")
                onClicked: refresh()
            }
            MenuItem {
                text: qsTr("Play as Playlist")
                onClicked: playAsPlaylist()
            }
        }

        header: Column {
            id: lvColumn

            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium
            anchors.bottomMargin: Theme.paddingLarge
            spacing: Theme.paddingMedium

            PageHeader {
                id: pHeader
                width: parent.width
                title: {
                    switch(recommendationMode) {
                    default:
                    case 0: return Util.createPageHeaderLabel(qsTr("Recommended "), qsTr("Seeds"), Theme)
                    case 1: return Util.createPageHeaderLabel(qsTr("Recommended "), qsTr("Seeds+Attributes"), Theme)
                    }
                }
                MenuButton { z: 1} // set z so you can still click the button
                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: true
                    onClicked: {
                        nextRecommendationMode()
                        refresh()
                    }
                }
            }

            // Genre Seeds
            ValueButton {
                id: genresButton
                property var indexes: []
                width: parent.width
                label: qsTr("Genres")

                ListModel {
                    id: items
                }

                Connections {
                    target: app
                    onHasValidTokenChanged: genresButton.loadItems()
                }

                Component.onCompleted: genresButton.loadItems()

                function loadItems() {
                    if(searchModel.count > 0)
                        return

                    value = qsTr("None")
                    indexes = []

                    // load possible choices
                    Spotify.getAvailableGenreSeeds(function(error, data) {
                        if(data) {
                            var i

                            // add selectables
                            for(i=0;i<data.genres.length;i++)
                                items.append({id: i, name: data.genres[i]})

                            // read the selected
                            var seeds = app.genre_seeds.value
                            if(seeds.length > 0)
                                value = ""
                            for(var j=0;j<seeds.length;j++) {
                                for(i=0;i<items.count;i++) {
                                    if(seeds[j] === items.get(i).name) {
                                        indexes.push(i)
                                        genreSeeds.push(seeds[j])
                                        value += ((j>0)?", ":"") + seeds[j]
                                    }
                                }
                            }

                            refresh()
                        } else
                            console.log("getAvailableGenreSeeds returned no Genres")
                    })


                }

                onClicked: {
                    if(items.count === 0)
                        loadItems()
                    var ms = pageStack.push(Qt.resolvedUrl("../components/MultiItemPicker.qml"),
                                            { items: items, label: label, indexes: indexes } );
                    ms.accepted.connect(function() {
                        indexes = ms.indexes.sort(function (a, b) { return a - b })
                        genreSeeds = []
                        if (indexes.length == 0) {
                            value = qsTr("None")
                        } else {
                            value = ""
                            for(var i=0;i<indexes.length;i++) {
                                var name = items.get(indexes[i]).name
                                value += ((i>0) ? ", " : "") + name
                                genreSeeds.push(name)
                            }
                        }
                        if(genreSeeds.length > 5)
                            app.showErrorMessage(undefined, qsTr("Spotify allows max. 5 seeds"))
                        refresh()
                        app.genre_seeds.value = genreSeeds
                    })
                }

            }

            // Attributes
            Column {
                id: attributesColumn
                width: parent.width
                visible: recommendationMode == 1

                Slider {
                    id: energySlider
                    width: parent.width
                    minimumValue: 0
                    maximumValue: 1.0
                    label: qsTr("Energy")
                    onReleased: {
                        app.recommended_attributes.energy = value
                        refresh()
                    }
                }
                Slider {
                    id: danceabilitySlider
                    width: parent.width
                    minimumValue: 0
                    maximumValue: 1.0
                    label: qsTr("Danceability")
                    onReleased: {
                        app.recommended_attributes.danceability = value
                        refresh()
                    }
                }
                Slider {
                    id: instrumentalnessSlider
                    width: parent.width
                    minimumValue: 0
                    maximumValue: 1.0
                    label: qsTr("Instrumentalness")
                    onReleased: {
                        app.recommended_attributes.instrumentalness = value
                        refresh()
                    }
                }
                Slider {
                    id: speechinessSlider
                    width: parent.width
                    minimumValue: 0
                    maximumValue: 1.0
                    label: qsTr("Speechiness")
                    onReleased: {
                        app.recommended_attributes.speechiness = value
                        refresh()
                    }
                }
                Slider {
                    id: acousticnessSlider
                    width: parent.width
                    minimumValue: 0
                    maximumValue: 1.0
                    label: qsTr("Acousticness")
                    onReleased: {
                        app.recommended_attributes.acousticness = value
                        refresh()
                    }
                }
                Slider {
                    id: livenessSlider
                    width: parent.width
                    minimumValue: 0
                    maximumValue: 1.0
                    label: qsTr("Liveness")
                    onReleased: {
                        app.recommended_attributes.liveness = value
                        refresh()
                    }
                }
                Slider {
                    id: valenceSlider
                    width: parent.width
                    minimumValue: 0
                    maximumValue: 1.0
                    label: qsTr("Positiveness")
                    onReleased: {
                        app.recommended_attributes.valence = value
                        refresh()
                    }
                }
                Slider {
                    id: popularitySlider
                    width: parent.width
                    minimumValue: 0
                    maximumValue: 100
                    label: qsTr("Popularity")
                    onReleased: {
                        app.recommended_attributes.popularity = value
                        refresh()
                    }
                }
                onVisibleChanged: {
                    if(!visible)
                        return
                    energySlider.value = app.recommended_attributes.energy
                    danceabilitySlider.value = app.recommended_attributes.danceability
                    instrumentalnessSlider.value = app.recommended_attributes.instrumentalness
                    speechinessSlider.value = app.recommended_attributes.speechiness
                    acousticnessSlider.value = app.recommended_attributes.acousticness
                    livenessSlider.value = app.recommended_attributes.liveness
                    valenceSlider.value = app.recommended_attributes.valence
                    popularitySlider.value = app.recommended_attributes.popularity
                    refresh()
                }
            }
        }

        delegate: ListItem {
            id: listItem
            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium
            contentHeight: Theme.itemSizeLarge

            SearchResultListItem {
                id: searchResultListItem
                dataModel: model
            }

            menu: SearchResultContextMenu {}

            onClicked: {
                app.pushPage(Util.HutspotPage.Album, {album: track.album})
            }
        }

        VerticalScrollDecorator {}

        ViewPlaceholder {
            enabled: listView.count === 0
            text: qsTr("No Recommendations found")
            hintText: qsTr("Enter Seeds/Attributes and Reload")
        }

    }

    function nextRecommendationMode() {
        switch(recommendationMode) {
        case 0:
            recommendationMode = 1
            break;
        default:
        case 1:
            recommendationMode = 0
            break;
        }
    }

    function refresh() {
        var i;
        //showBusy = true
        searchModel.clear()

        if(genreSeeds.length === 0)
            return

        var gs = genreSeeds.slice(0,5) // Spotify allows max 5 seed entries
        var options = {seed_genres: gs.join(',')}

        if(recommendationMode > 0) {
            options.target_energy = app.recommended_attributes.energy
            options.target_danceability = app.recommended_attributes.danceability
            options.target_instrumentalness = app.recommended_attributes.instrumentalness
            options.target_speechiness = app.recommended_attributes.speechiness
            options.target_acousticness = app.recommended_attributes.acousticness
            options.target_liveness = app.recommended_attributes.liveness
            options.target_valence = app.recommended_attributes.valence
            options.target_popularity = app.recommended_attributes.popularity
        }

        options.limit = app.searchLimit.value
        if(app.query_for_market.value)
            options.market = "from_token"
        Spotify.getRecommendations(options, function(error, data) {
            if(data) {
                try {
                    console.log("number of Recommendations: " + data.tracks.length)
                    for(i=0;i<data.tracks.length;i++) {
                        searchModel.append({type: 3,
                                            name: data.tracks[i].name,
                                            track: data.tracks[i]})
                    }
                } catch (err) {
                    console.log(err)
                }
            } else
                console.log("No Data for getRecommendations")
        })

    }

    function playAsPlaylist(state) {
        var uris = [searchModel.count]
        for(var i=0;i<searchModel.count;i++)
            uris[i] = searchModel.get(i).track.uri
        app.queue.replaceQueueWith(uris)
    }

    Connections {
        target: app

        onLoggedInChanged: {
            if(app.loggedIn)
                refresh()
        }

        onHasValidTokenChanged: refresh()

    }

    Component.onCompleted: {
        if(app.hasValidToken)
            refresh()
    }

    // The shared DockedPanel needs mouse events
    // and some ListView events
    propagateComposedEvents: true
    onStatusChanged: {
        if(status === PageStatus.Activating)
            app.dockedPanel.registerListView(listView)
        else if(status === PageStatus.Deactivating)
            app.dockedPanel.unregisterListView(listView)
    }
}
