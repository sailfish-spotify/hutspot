#ifndef SERVICEBROWSER_H
#define SERVICEBROWSER_H

#include <QObject>

#include "qtzeroconf/zconfservicebrowser.h"

class ServiceBrowser : public QObject
{
    Q_OBJECT
public:
    explicit ServiceBrowser(QObject *parent = 0);

signals:
    void serviceEntryAdded(QString service);
    void serviceEntryRemoved(QString service);

public slots:
    Q_INVOKABLE void browse(const QString &scope);
    Q_INVOKABLE QString getJSON(const QString &scope);

private slots:
    void onServiceEntryAdded(QString service);
    void onServiceEntryRemoved(QString service);

private:
    ZConfServiceBrowser * zcsBrowser;
};

#endif // SERVICEBROWSER_H
