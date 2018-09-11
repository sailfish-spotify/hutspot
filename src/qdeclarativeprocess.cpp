#include "qdeclarativeprocess.h"
#include <QQuickItem>

QDeclarativeProcess::QDeclarativeProcess(QQuickItem *parent) :
    QProcess(parent),
    m_outputProcess(0)
{
    this->connect(this, SIGNAL(error(QProcess::ProcessError)), this, SIGNAL(errorChanged()));
    this->connect(this, SIGNAL(finished(int,QProcess::ExitStatus)), this, SLOT(onFinished(int,QProcess::ExitStatus)));
    this->connect(this, SIGNAL(finished(int,QProcess::ExitStatus)), this, SIGNAL(exitCodeChanged()));
    this->connect(this, SIGNAL(finished(int,QProcess::ExitStatus)), this, SIGNAL(exitStatusChanged()));
    this->connect(this, SIGNAL(stateChanged(QProcess::ProcessState)), this, SLOT(onStateChanged(QProcess::ProcessState)));
    this->connect(this, SIGNAL(stateChanged(QProcess::ProcessState)), this, SIGNAL(pidChanged()));
}

void QDeclarativeProcess::setCommand(const QString &command) {
    if (command != m_command) {
        m_command = command;
        emit commandChanged();
    }
}

void QDeclarativeProcess::closeReadChannel(QDeclarativeProcessEnums::ProcessChannel channel) {
    QProcess::closeReadChannel(QProcess::ProcessChannel(channel));
}

void QDeclarativeProcess::closeWriteChannel() {
    QProcess::closeWriteChannel();
}

QString QDeclarativeProcess::readAllStandardError() {
    return QString(QProcess::readAllStandardError());
}

QString QDeclarativeProcess::readAllStandardOutput() {
    return QString(QProcess::readAllStandardOutput());
}

void QDeclarativeProcess::start() {
    QProcess::start(this->command());
}

void QDeclarativeProcess::start(QString program, QStringList arguments) {
    QProcess::start(program, arguments);
}

void QDeclarativeProcess::write(QString data) {
    QProcess::write(data.toUtf8(), data.length());
}

void QDeclarativeProcess::setStandardErrorFile(const QString &fileName) {
    m_errorFile = fileName;
    QProcess::setStandardErrorFile(fileName);
}

void QDeclarativeProcess::setStandardInputFile(const QString &fileName) {
    m_inputFile = fileName;
    QProcess::setStandardInputFile(fileName);
}

void QDeclarativeProcess::setStandardOutputFile(const QString &fileName) {
    m_outputFile = fileName;
    QProcess::setStandardOutputFile(fileName);
}

void QDeclarativeProcess::setStandardOutputProcess(QDeclarativeProcess *destination) {
    m_outputProcess = destination;
    QProcess::setStandardOutputProcess(destination);
}

QVariantMap QDeclarativeProcess::processEnvironment() {
    QVariantMap envMap;

    foreach (QString value, QProcess::processEnvironment().toStringList()) {
        envMap.insert(value.section('=', 0, 0), value.section('=', 1, 1));
    }

    return envMap;
}

void QDeclarativeProcess::setProcessEnvironment(const QVariantMap &envMap) {
    QProcessEnvironment env;

    foreach(QString key, envMap.keys()) {
        env.insert(key, envMap.value(key).toString());
    }

    QProcess::setProcessEnvironment(env);
    emit processEnvironmentChanged();
}

void QDeclarativeProcess::setWorkingDirectory(const QString &dir) {
    if (dir != this->workingDirectory()) {
        QProcess::setWorkingDirectory(dir);
        emit workingDirectoryChanged();
    }
}

void QDeclarativeProcess::setProcessChannelMode(QDeclarativeProcessEnums::ProcessChannelMode mode) {
    QProcess::setProcessChannelMode(QProcess::ProcessChannelMode(mode));
}

void QDeclarativeProcess::setReadChannel(QDeclarativeProcessEnums::ProcessChannel channel) {
    QProcess::setReadChannel(QProcess::ProcessChannel(channel));
}

QDeclarativeProcessEnums::ProcessError QDeclarativeProcess::error() const {
    return QDeclarativeProcessEnums::ProcessError(QProcess::error());
}

QDeclarativeProcessEnums::ProcessChannel QDeclarativeProcess::readChannel() const {
    return QDeclarativeProcessEnums::ProcessChannel(QProcess::readChannel());
}

QDeclarativeProcessEnums::ProcessChannelMode QDeclarativeProcess::processChannelMode() const {
    return QDeclarativeProcessEnums::ProcessChannelMode(QProcess::processChannelMode());
}

QDeclarativeProcessEnums::ExitStatus QDeclarativeProcess::exitStatus() const {
    return QDeclarativeProcessEnums::ExitStatus(QProcess::exitStatus());
}

QDeclarativeProcessEnums::ProcessState QDeclarativeProcess::state() const {
    return QDeclarativeProcessEnums::ProcessState(QProcess::state());
}

void QDeclarativeProcess::onStateChanged(QProcess::ProcessState state) {
    emit stateChanged(QDeclarativeProcessEnums::ProcessState(state));
}

void QDeclarativeProcess::onFinished(int exitCode, QProcess::ExitStatus exitStatus) {
    emit finished(exitCode, QDeclarativeProcessEnums::ExitStatus(exitStatus));
}
