#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QDesktopServices>
#include <QDebug>

#ifdef QT_QML_DEBUG
#include <QtQuick>
#else
#include <QQuickView>
#include <QQmlContext>
#include <QGuiApplication>
#include <QTranslator>
#endif

#include "spotify.h"

#include "o2/o0globals.h"
#include "o2/o2requestor.h"
#include "o2/o0settingsstore.h"

//#error Setup your Spotify application "https://beta.developer.spotify.com/dashboard/applications"
const char O2_CONSUMER_KEY[] = "388f2d2f105b45ef95e159ac87ef5733";
const char O2_CONSUMER_SECRET[] = "c926747234ef4fc8aefb2759f2c3d571";
const int localPort = 8888;

Spotify::Spotify(QObject *parent) : QObject(parent)
{
    o2Spotify = NULL;
}

void Spotify::doO2Auth(const QString &scope) {
    if(o2Spotify == NULL) {
        // redirect URL will be http://127.0.0.1:8888/
        o2Spotify = new O2Spotify(this);
        o2Spotify->setClientId(O2_CONSUMER_KEY);
        o2Spotify->setClientSecret(O2_CONSUMER_SECRET);
        o2Spotify->setLocalPort(localPort);
        if(scope.length() > 0)
            o2Spotify->setScope(scope);

        // Create a store object for writing the received tokens
        O0SettingsStore *store = new O0SettingsStore(O2_ENCRYPTION_KEY);
        store->setGroupKey("spotify");
        o2Spotify->setStore(store);

        o2Spotify->setReplyContent("<html><body><h1>spotify-for-sailfish: auth redirected</h1><h1>You can close this window. Return to the App.</h1></body></html>");

        // Connect signals
        connect(o2Spotify, SIGNAL(linkedChanged()), this, SLOT(onLinkedChanged()));
        connect(o2Spotify, SIGNAL(linkingFailed()), this, SLOT(onLinkingFailed()));
        connect(o2Spotify, SIGNAL(linkingSucceeded()), this, SLOT(onLinkingSucceeded()));
        connect(o2Spotify, SIGNAL(openBrowser(QUrl)), this, SLOT(onOpenBrowser(QUrl)));
        connect(o2Spotify, SIGNAL(closeBrowser()), this, SLOT(onCloseBrowser()));
        connect(o2Spotify, SIGNAL(refreshFinished(QNetworkReply::NetworkError)), this, SLOT(onRefreshFinished(QNetworkReply::NetworkError)));

        //o2Spotify->unlink();  // for expired token
    }

    qDebug() << "Starting OAuth...";
    //o2Spotify->unlink();  // ??
    o2Spotify->link();
    //o2Spotify->refresh();
}

QString Spotify::getUserName() {
    if(o2Spotify)
        return o2Spotify->username();
    return "";
}

QString Spotify::getToken() {
    if(o2Spotify)
        return o2Spotify->token();
    return "";
}

void Spotify::refreshToken() {
    if(o2Spotify)
        o2Spotify->refresh();
}

int Spotify::getExpires() {
    if(o2Spotify)
        o2Spotify->expires();
    return -1;
}

void Spotify::onOpenBrowser(const QUrl &url) {
    qDebug() << "Opening browser with URL" << url.toString();
    QDesktopServices::openUrl(url);
}

void Spotify::onCloseBrowser() {
    // don't know how to close the broser tab/window and switch to ourselves
    qDebug() << "Spotify::onCloseBrowser()";
}

void Spotify::onRefreshFinished(QNetworkReply::NetworkError error) {
    //QNetworkReply *tokenReply = qobject_cast<QNetworkReply *>(sender());
    //qDebug() << "Spotify::onRefreshFinished(): " << error << ", " << tokenReply->errorString();
    qDebug() << "Spotify::onRefreshFinished(): " << error;
}

void Spotify::onLinkedChanged() {
    qDebug() << "Linked changed!";
}

void Spotify::onLinkingSucceeded() {
    O2Spotify *o2s = qobject_cast<O2Spotify *>(sender());
    if (!o2s->linked()) {
        return;
    }
    QVariantMap extraTokens = o2s->extraTokens();
    if (!extraTokens.isEmpty()) {
        emit extraTokensReady(extraTokens);
        qDebug() << "Extra tokens in response:";
        foreach (QString key, extraTokens.keys()) {
            qDebug() << "\t" << key << ":" << (extraTokens.value(key).toString().left(3) + "...");
        }
    }
    emit linkingSucceeded();
}

void Spotify::onLinkingFailed() {
    qDebug() << "Linking failed!";
    emit linkingFailed();
}
