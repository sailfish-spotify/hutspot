#include "servicebrowser.h"

#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>

ServiceBrowser::ServiceBrowser(QObject *parent) {
    zcsBrowser = new ZConfServiceBrowser(parent);

    // Connect signals
    connect(zcsBrowser, SIGNAL(serviceEntryAdded(QString)), this, SLOT(onServiceEntryAdded(QString)));
    connect(zcsBrowser, SIGNAL(serviceEntryRemoved(QString)), this, SLOT(onServiceEntryRemoved(QString)));
}

void ServiceBrowser::browse(const QString &scope) {
    if(zcsBrowser)
        zcsBrowser->browse(scope);
}

QString ServiceBrowser::getJSON(const QString &scope) {
    if(!zcsBrowser)
        return QString("");

    ZConfServiceEntry entry = zcsBrowser->serviceEntry(scope);

    QJsonObject properties;
    properties["ip"] = entry.ip;
    properties["domain"] = entry.domain;
    properties["host"] = entry.host;
    properties["port"] = entry.port;
    properties["protocol"] = entry.protocolName();

    QJsonDocument doc(properties);
    return doc.toJson(QJsonDocument::Compact);
}

void ServiceBrowser::onServiceEntryAdded(QString service) {
    emit serviceEntryAdded(service);
}

void ServiceBrowser::onServiceEntryRemoved(QString service) {
    emit serviceEntryRemoved(service);
}
