# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = playspot

CONFIG += sailfishapp

SOURCES += src/playspot.cpp \
    src/o2/o0baseauth.cpp \
    src/o2/o0settingsstore.cpp \
    src/o2/o2.cpp \
    src/o2/o2reply.cpp \
    src/o2/o2replyserver.cpp \
    src/o2/o2spotify.cpp \
    src/o2/o2simplecrypt.cpp \
    src/spotify.cpp

DISTFILES += qml/playspot.qml \
    qml/cover/CoverPage.qml \
    qml/pages/FirstPage.qml \
    rpm/playspot.changes.in \
    rpm/playspot.changes.run.in \
    rpm/playspot.spec \
    rpm/playspot.yaml \
    translations/*.ts \
    playspot.desktop \
    qml/pages/Search.qml \
    qml/components/SearchResultListItem.qml

SAILFISHAPP_ICONS = 86x86 108x108 128x128

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/playspot-de.ts

HEADERS += \
    src/o2/o0abstractstore.h \
    src/o2/o0baseauth.h \
    src/o2/o0export.h \
    src/o2/o0globals.h \
    src/o2/o0requestparameter.h \
    src/o2/o0settingsstore.h \
    src/o2/o0simplecrypt.h \
    src/o2/o2.h \
    src/o2/o2reply.h \
    src/o2/o2replyserver.h \
    src/o2/o2spotify.h \
    src/spotify.h
