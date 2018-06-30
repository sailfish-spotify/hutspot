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

public slots:
    Q_INVOKABLE void doO2Auth(const QString &scope);
    Q_INVOKABLE QString getUserName();
    Q_INVOKABLE QString getToken();
    Q_INVOKABLE void refreshToken();

private slots:
    void onLinkedChanged();
    void onLinkingSucceeded();
    void onLinkingFailed();
    void onOpenBrowser(const QUrl &url);
    void onCloseBrowser();

private:
    O2Spotify * o2Spotify;
};

#endif // SPOTIFY_H
