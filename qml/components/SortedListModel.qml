import QtQuick 2.0

ListModel {

    // from https://gist.github.com/stephenquan/fcad6ecd4b28051c61cf48853e39c9e4

    property string sortKey: "name"
    property var comparator: null

    onSortKeyChanged: update()
    onComparatorChanged: update()

    function compareByValue(valueA, valueB) {
        if (typeof(valueA) === typeof(valueB)) {
            switch (valueA) {
            case "string": return valueA.localeCompare(valueB);
            case "number": return valueA - valueB;
            }
        }

        return valueA.toString().localeCompare(valueB.toString());
    }

    function compareByKey(itemA, itemB, key) {
        var m = key.match(/^-(.*)$/);
        if (m) return - compareByValue(itemA[m[1]], itemB[m[1]]);
        return compareByValue(itemA[key], itemB[key]);
    }

    function compareByKeys(itemA, itemB, keys) {
        var arr = keys.split(",");
        for (var i = 0; i < arr.length; i++) {
            var cmp = compareByKey(itemA, itemB, arr[i]);
            if (cmp !== 0) return cmp;
        }
        return 0;
    }

    function compare(itemA, itemB) {
        return comparator ? comparator(itemA, itemB) : compareByKeys(itemA, itemB, sortKey);
    }

    function add(item) {
        if (!count) {
            append(item);
            return;
        }

        var cmp = compare(item, get(0));

        if (cmp === 0) {
            set(0, item);
            return;
        }
        if (cmp < 0) {
            insert(0, item);
            return;
        }

        if (count > 1) {
            cmp = compare(item, get(count - 1));
            if (cmp === 0) {
                set(count - 1, item);
                return;
            }
        }

        if (cmp > 0) {
            append(item);
            return;
        }

        var first = 0;
        var last = count - 1;
        while (last > first + 1) {
            var mid = (first + last) >> 1;
            cmp = compare(item, get(mid));
            if (cmp === 0) {
                set(mid, item);
                return;
            }

            if (cmp < 0) {
                last = mid;
            } else {
                first = mid;
            }
        }

        insert(last, item);
    }

    function update() {
        var indexes = new Array(count);
        for (var i = 0; i < count; i++) {
            indexes[i] = i;
        }
        indexes = indexes.sort(function (indexA, indexB) { return compare(get(indexA), get(indexB)) } );
        for (var j = 0; j < count; j++) {
            var k = indexes[j];
            move(k, j, 1);
            indexes = indexes.map(function(e) { return e >= j && e < k ? e + 1 : e; } );
        }
    }
}

