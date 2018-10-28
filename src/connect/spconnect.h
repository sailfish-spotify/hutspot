#ifndef SPCONNECT_H
#define SPCONNECT_H

#include <QObject>
#include <QTimer>

#include <openssl/dh.h>
#include "connectmdnsservice.h"

class SPConnect : public QObject
{
    Q_OBJECT
public:
    explicit SPConnect(QObject *parent = nullptr);

    QByteArray hmacSha1(QByteArray key, QByteArray baseString);
    Q_INVOKABLE QString base64Decode(QString data);
    Q_INVOKABLE QString base64Encode(QString data);
    Q_INVOKABLE void startMDNSService(void);
    Q_INVOKABLE void stopMDNSService(void);

public slots:
    Q_INVOKABLE QString getDeviceId(QString deviceName);
    Q_INVOKABLE void setCredentials(QString userName, int authType, QString authData);
    Q_INVOKABLE QString createBlobToSend(QString deviceName, QString clientKey);
    Q_INVOKABLE QString getPublicKey();

protected:
    DH * dh;
    QString deviceId64;
    QString publicKey64;

    ConnectMDNSService * mdnsService;
    QTimer mdnsTimer;

    QByteArray cred_auth_blob;

    // will be loaded from credentials
    QString cred_auth_user_name;
    int cred_auth_type;
    QByteArray cred_auth_data;

    // will be created out of the credentials
    QByteArray encrypted_blob64;
};

#endif // SPCONNECT_H
