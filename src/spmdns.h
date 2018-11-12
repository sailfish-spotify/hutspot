#ifndef MDNS_H
#define MDNS_H

#include <QObject>
#include <QMap>

#include "qmdnsengine/server.h"
#include "qmdnsengine/service.h"
#include "qmdnsengine/browser.h"
#include "qmdnsengine/resolver.h"
#include "qmdnsengine/cache.h"

#include <QHostAddress>

class SPMDNS : public QObject
{
    Q_OBJECT
public:
    explicit SPMDNS(QObject *parent = nullptr);

signals:
    void serviceAdded(QString serviceJSON);
    void serviceUpdated(QString serviceJSON);
    void serviceRemoved(QString name);
    void serviceResolved(QString name, QString address);

public slots:

protected slots:
    void serviceAddedCallback(const QMdnsEngine::Service &service);
    void serviceUpdatedCallback(const QMdnsEngine::Service &service);
    void serviceRemovedCallback(const QMdnsEngine::Service &service);
    void resolvedCallback(QString name, const QHostAddress &address);

protected:
    void serviceChangedHandler(const QMdnsEngine::Service &service, bool added);

    QMdnsEngine::Server * server;
    QMdnsEngine::Cache * cache;
    QMdnsEngine::Browser * browser;
    QMap <QString, QMdnsEngine::Resolver *> resolvers;
};

#endif // MDNS_H
