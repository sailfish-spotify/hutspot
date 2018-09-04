
import QtQuick 2.0
import Sailfish.Silica 1.0

ComboBox {
    id: searchField

    property alias placeholderText: searchTextField.placeholderText
    property alias text: searchTextField.text
    property alias searchTextField: searchTextField

    value: "" // Combobox wants to show the first menu item. we don't.

    MySearchField {
        id: searchTextField
        width: parent.width

        clearButtonIconSource: "image://theme/icon-m-down"
        onClearButtonPressed: searchField.menu.open(searchField)
    }

    function forceActiveFocus() {
        searchTextField._editor.forceActiveFocus()
    }
}
