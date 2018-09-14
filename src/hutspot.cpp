/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

#ifdef QT_QML_DEBUG
#include <QtQuick>
#else
#include <QQuickView>
#include <QQmlContext>
#include <QGuiApplication>
#include <QTranslator>
#include <QDebug>
#endif

#include <sailfishapp.h>

#include "IconProvider.h"
#include "spotify.h"
//#include "servicebrowser.h"
#include "qdeclarativeprocess.h"

int main(int argc, char *argv[])
{
    QGuiApplication * app = SailfishApp::application(argc,argv);
    QQuickView * view = SailfishApp::createView();

    QCoreApplication::setOrganizationName("wdehoog");
    QCoreApplication::setOrganizationDomain("wdehoog");
    QCoreApplication::setApplicationName("hutspot");

    Spotify spotify;
    view->rootContext()->setContextProperty("spotify", &spotify);

    qmlRegisterUncreatableType<QDeclarativeProcessEnums>("org.hildon.components", 1, 0, "Processes", "");
    qmlRegisterType<QDeclarativeProcess>("org.hildon.components", 1, 0, "Process");

    // custom icon loader
    QQmlEngine *engine = view->engine();
    engine->addImageProvider(QLatin1String("hutspot-icons"), new IconProvider);

//    ServiceBrowser serviceBrowser;
//    view->rootContext()->setContextProperty("serviceBrowser", &serviceBrowser);

    view->setSource(SailfishApp::pathTo("qml/hutspot.qml"));
    view->show();

    return app->exec();
}
