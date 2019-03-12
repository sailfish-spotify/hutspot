import QtQuick 2.0

import "../Util.js" as Util

Item {

    property int limit: app.searchLimit.value
    property int offset: 0
    property int total: 0
    property bool canLoadNext: ((offset + limit) <= total)
                               || (useHas && hasNext)
    property bool canLoadPrevious: offset >= limit
                                   || (useHas && hasPrevious)
    property bool useHas: false
    property bool hasNext: false
    property bool hasPrevious: false
    property var before
    property var after

    /*signal loadNext()
    signal loadPrevious()

    function next() {
        offset += limit
        loadNext()
    }

    function previous() {
        offset -= limit
        if(offset < 0)
            offset = 0
        loadPrevious()
    }*/

    function update(cursor) {
        offset = cursor.offset
        total = cursor.total
        hasNext = cursor.hasNext
        hasPrevious = cursor.hasPrevious
        after = cursor.after ? cursor.after : 0
        before = cursor.before ? cursor.before : 0
    }
}

