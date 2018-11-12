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
#include "spmdns.h"
#include "connect/spconnect.h"
#include "qdeclarativeprocess.h"

int main(int argc, char *argv[])
{
    QGuiApplication * app = SailfishApp::application(argc,argv);
    QQuickView * view = SailfishApp::createView();

    QCoreApplication::setOrganizationName("wdehoog");
    QCoreApplication::setOrganizationDomain("wdehoog");
    QCoreApplication::setApplicationName("hutspot");

    QString buildDateTime;
    buildDateTime.append(__DATE__);
    buildDateTime.append(" ");
    buildDateTime.append(__TIME__);
    view->rootContext()->setContextProperty("BUILD_DATE_TIME", buildDateTime);

    Spotify spotify;
    view->rootContext()->setContextProperty("spotify", &spotify);

    qmlRegisterUncreatableType<QDeclarativeProcessEnums>("org.hildon.components", 1, 0, "Processes", "");
    qmlRegisterType<QDeclarativeProcess>("org.hildon.components", 1, 0, "Process");

    // custom icon loader
    QQmlEngine *engine = view->engine();
    engine->addImageProvider(QLatin1String("hutspot-icons"), new IconProvider);

    SPMDNS spMdns;
    view->rootContext()->setContextProperty("spMdns", &spMdns);

    SPConnect spConnect;
    view->rootContext()->setContextProperty("spConnect", &spConnect);

    view->setSource(SailfishApp::pathTo("qml/hutspot.qml"));
    view->show();

    return app->exec();
}
