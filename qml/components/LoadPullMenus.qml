import QtQuick 2.0
import Sailfish.Silica 1.0

import "../Util.js" as Util

PullDownMenu {
    MenuItem {
        text: qsTr("Reload")
        onClicked: refresh()
    }
    MenuItem {
        text: qsTr("Load Next Set")
              //+ (enabled
              //   ? " " + Util.getNextCursorText(cursor_offset, cursor_limit, cursor_total)
              //   : "")
        enabled: canLoadNext
        onClicked: {
            cursor_offset += cursor_limit
            refresh()
        }
    }
    MenuItem {
        text: qsTr("Load Previous Set")
              //+ (enabled
              //   ? " " + Util.getPreviousCursorText(cursor_offset, cursor_limit, cursor_total)
              //   : "")
        enabled: canLoadPrevious
        onClicked: {
            cursor_offset -= cursor_limit
            if(cursor_offset < 0)
                cursor_offset = 0
            refresh()
        }
    }
}
