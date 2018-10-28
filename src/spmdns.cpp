#include "spmdns.h"

#include "qmdnsengine/resolver.h"
#include "qmdnsengine/service.h"

#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>

SPMDNS::SPMDNS(QObject *parent) : QObject(parent) {
    this->server = new  QMdnsEngine::Server();
    this->cache = new QMdnsEngine::Cache();
    this->browser = new QMdnsEngine::Browser(server, "_spotify-connect._tcp.local.", cache);
    resolver = nullptr;

    connect(browser, &QMdnsEngine::Browser::serviceAdded, this, &SPMDNS::serviceAddedCallback);
    connect(browser, &QMdnsEngine::Browser::serviceUpdated, this, &SPMDNS::serviceUpdatedCallback);
    connect(browser, &QMdnsEngine::Browser::serviceRemoved, this, &SPMDNS::serviceRemovedCallback);
}

void SPMDNS::serviceChangedHandler(const QMdnsEngine::Service &service, bool added) {
    QJsonObject properties;
    properties["name"] = QString::fromStdString(service.name().toStdString());
    properties["CPath"] = QString::fromStdString(service.attributes()["CPath"].toStdString());
    properties["VERSION"] = QString::fromStdString(service.attributes()["VERSION"].toStdString());
    properties["host"] = QString::fromStdString(service.hostname().toStdString());
    properties["port"] = service.port();
    properties["type"] = QString::fromStdString(service.type().toStdString());
    QJsonDocument doc(properties);
    QString json = doc.toJson(QJsonDocument::Compact);
    if(added)
        emit serviceAdded(json);
    else
        emit serviceUpdated(json);

    // resolve it
    if(resolver) {
        delete resolver;
        resolver = nullptr;
    }
    resolver = new QMdnsEngine::Resolver(server, service.hostname(), cache);
    connect(resolver, &QMdnsEngine::Resolver::resolved, this, &SPMDNS::resolvedCallback);
}

void SPMDNS::serviceAddedCallback(const QMdnsEngine::Service &service) {
    //qDebug() << service.name() << " discovered";
    serviceChangedHandler(service, true);
}

void SPMDNS::serviceUpdatedCallback(const QMdnsEngine::Service &service) {
    //qDebug() << service.name() << " updated";
    serviceChangedHandler(service, false);
}

void SPMDNS::serviceRemovedCallback(const QMdnsEngine::Service &service) {
    emit serviceRemoved(service.name());
}

void SPMDNS::resolvedCallback(QString name, const QHostAddress &address) {
    //qDebug() << "resolved " << name << " to " << address;
    if(address.protocol() == QAbstractSocket::IPv4Protocol)
        emit serviceResolved(name, address.toString());
}

