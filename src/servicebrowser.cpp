#include "servicebrowser.h"

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

void ServiceBrowser::onServiceEntryAdded(QString service) {
    emit serviceEntryAdded(service);
}

void ServiceBrowser::onServiceEntryRemoved(QString service) {
    emit serviceEntryRemoved(service);
}
