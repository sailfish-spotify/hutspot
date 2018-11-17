#ifndef CONNECTSERVICE_H
#define CONNECTSERVICE_H

#include <QObject>

#include <qmdnsengine/server.h>
#include <qmdnsengine/service.h>
#include <qmdnsengine/hostname.h>
#include <qmdnsengine/message.h>
#include <qmdnsengine/provider.h>
#include <qmdnsengine/query.h>
#include <qmdnsengine/dns.h>

class ConnectMDNSService : public QObject
{
    Q_OBJECT
public:
    explicit ConnectMDNSService(QObject *parent = nullptr);
    virtual ~ConnectMDNSService();

signals:

public slots:
    void onMessageReceived(const QMdnsEngine::Message &message);
    void broadcastService();

protected:
    QMdnsEngine::Service service;
    QMdnsEngine::Server mServer;
    QMdnsEngine::Hostname mHostname;
    QMdnsEngine::Provider *mProvider;

};

#endif // CONNECTSERVICE_H
