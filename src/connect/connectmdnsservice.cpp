#include "connectmdnsservice.h"

#include <QDebug>

ConnectMDNSService::ConnectMDNSService(QObject *parent) : QObject(parent),
    mHostname(&mServer),
    mProvider(0) {

    //connect(&mServer, &QMdnsEngine::Server::messageReceived, this, &ConnectMDNSService::onMessageReceived);

    service.setName("Hutspot");
    service.setType("_spotify-connect._tcp.local.");
    service.setPort(44929); // FixMe what port to use or get one automatic?

    service.addAttribute("CPath", "/");
    service.addAttribute("VERSION", "1.0");

    mProvider = new QMdnsEngine::Provider(&mServer, &mHostname, this);
    mProvider->update(service);
}

ConnectMDNSService::~ConnectMDNSService() {
    if(mProvider) {
        delete mProvider;
        mProvider = nullptr;
    }
}

void ConnectMDNSService::onMessageReceived(const QMdnsEngine::Message &message) {
    foreach (QMdnsEngine::Query query, message.queries()) {
        qDebug() <<
            tr("[%1] %2")
                .arg(QMdnsEngine::typeName(query.type()))
                .arg(QString(query.name()));
    }
}

void ConnectMDNSService::broadcastService() {
    mProvider->update(service);
}
