#ifndef SPOTIFY_H
#define SPOTIFY_H

#include <QObject>

#include "o2/o2spotify.h"

class Spotify : public QObject
{
    Q_OBJECT
public:
    explicit Spotify(QObject *parent = 0);

signals:
    void extraTokensReady(const QVariantMap &extraTokens);
    void linkingFailed();
    void linkingSucceeded();
    void linkedChanged();
    void refreshFinished(int errorCode, QString errorString);
    void openBrowser(const QUrl &url);
    void closeBrowser();

public slots:
    Q_INVOKABLE void doO2Auth(const QString &scope);
    Q_INVOKABLE QString getUserName();
    Q_INVOKABLE QString getToken();
    Q_INVOKABLE void refreshToken();
    Q_INVOKABLE int getExpires();
    Q_INVOKABLE bool isLinked();

private slots:
    void onLinkedChanged();
    void onLinkingSucceeded();
    void onLinkingFailed();
    void onOpenBrowser(const QUrl &url);
    void onCloseBrowser();
    void onRefreshFinished(QNetworkReply::NetworkError error, QString errorString);

private:
    O2Spotify * o2Spotify;
};

#endif // SPOTIFY_H
