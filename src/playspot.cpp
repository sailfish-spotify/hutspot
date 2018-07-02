/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <sailfishapp.h>

#include "spotify.h"

int main(int argc, char *argv[])
{
    // SailfishApp::main() will display "qml/playspot.qml", if you need more
    // control over initialization, you can use:
    //
    //   - SailfishApp::application(int, char *[]) to get the QGuiApplication *
    //   - SailfishApp::createView() to get a new QQuickView * instance
    //   - SailfishApp::pathTo(QString) to get a QUrl to a resource file
    //   - SailfishApp::pathToMainQml() to get a QUrl to the main QML file
    //
    // To display the view, call "show()" (will show fullscreen on device).

    QGuiApplication * app = SailfishApp::application(argc,argv);
    QQuickView * view = SailfishApp::createView();

    QCoreApplication::setOrganizationName("wdehoog");
    QCoreApplication::setOrganizationDomain("wdehoog");
    QCoreApplication::setApplicationName("playspot");

    Spotify spotify;
    view->rootContext()->setContextProperty("spotify", &spotify);

    view->setSource(SailfishApp::pathTo("qml/playspot.qml"));
    view->show();

    return app->exec();
}
