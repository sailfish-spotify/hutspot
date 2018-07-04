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
    void serviceEntryAdded(QString);
    void serviceEntryRemoved(QString);

public slots:
    Q_INVOKABLE void browse(const QString &scope);

private slots:
    void onServiceEntryAdded(QString);
    void onServiceEntryRemoved(QString);

private:
    ZConfServiceBrowser * zcsBrowser;
};

#endif // SERVICEBROWSER_H
