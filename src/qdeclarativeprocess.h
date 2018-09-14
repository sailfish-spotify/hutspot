#ifndef QDECLARATIVEPROCESS_H
#define QDECLARATIVEPROCESS_H

// see https://github.com/marx1an/qt-components-hildon

#include <QProcess>
#include <QVariant>

class QQuickItem;

class QDeclarativeProcessEnums : public QObject
{
    Q_OBJECT

    Q_ENUMS(ExitStatus)
    Q_ENUMS(ProcessChannel)
    Q_ENUMS(ProcessChannelMode)
    Q_ENUMS(ProcessError)
    Q_ENUMS(ProcessState)

public:
    enum ExitStatus {
        NormalExit = QProcess::NormalExit,
        CrashExit = QProcess::CrashExit
    };

    enum ProcessChannel {
        StandardOutput = QProcess::StandardOutput,
        StandardError = QProcess::StandardError
    };

    enum ProcessChannelMode {
        SeparateChannels = QProcess::SeparateChannels,
        MergedChannels = QProcess::MergedChannels,
        ForwardedChannels = QProcess::ForwardedChannels
    };

    enum ProcessError {
        FailedToStart = QProcess::FailedToStart,
        Crashed = QProcess::Crashed,
        Timedout = QProcess::Timedout,
        WriteError = QProcess::WriteError,
        ReadError = QProcess::ReadError,
        UnknownError = QProcess::UnknownError
    };

    enum ProcessState {
        NotRunning = QProcess::NotRunning,
        Starting = QProcess::Starting,
        Running = QProcess::Running
    };
};

class QDeclarativeProcess : public QProcess
{
    Q_OBJECT

    Q_PROPERTY(QString command
               READ command
               WRITE setCommand
               NOTIFY commandChanged)
    Q_PROPERTY(QString workingDirectory
               READ workingDirectory
               WRITE setWorkingDirectory
               NOTIFY workingDirectoryChanged)
    Q_PROPERTY(Q_PID pid
               READ pid
               NOTIFY pidChanged)
    Q_PROPERTY(QDeclarativeProcessEnums::ProcessError error
               READ error
               NOTIFY errorChanged)
    Q_PROPERTY(QDeclarativeProcessEnums::ProcessState state
               READ state
               NOTIFY stateChanged)
    Q_PROPERTY(int exitCode
               READ exitCode
               NOTIFY exitCodeChanged)
    Q_PROPERTY(QDeclarativeProcessEnums::ExitStatus exitStatus
               READ exitStatus
               NOTIFY exitStatusChanged)
    Q_PROPERTY(QDeclarativeProcessEnums::ProcessChannelMode processChannelMode
               READ processChannelMode
               WRITE setProcessChannelMode)
    Q_PROPERTY(QVariantMap processEnvironment
               READ processEnvironment
               WRITE setProcessEnvironment
               NOTIFY processEnvironmentChanged)
    Q_PROPERTY(QDeclarativeProcessEnums::ProcessChannel readChannel
               READ readChannel
               WRITE setReadChannel)
    Q_PROPERTY(QString standardErrorFile
               READ standardErrorFile
               WRITE setStandardErrorFile)
    Q_PROPERTY(QString standardInputFile
               READ standardInputFile
               WRITE setStandardInputFile)
    Q_PROPERTY(QString standardOutputFile
               READ standardOutputFile
               WRITE setStandardOutputFile)
    Q_PROPERTY(QDeclarativeProcess* standardOutputProcess
               READ standardOutputProcess
               WRITE setStandardOutputProcess)

public:
    explicit QDeclarativeProcess(QQuickItem *parent = 0);
    Q_INVOKABLE void closeReadChannel(QDeclarativeProcessEnums::ProcessChannel channel);
    Q_INVOKABLE void closeWriteChannel();
    Q_INVOKABLE QString readAllStandardError();
    Q_INVOKABLE QString readAllStandardOutput();
    Q_INVOKABLE void start();
    Q_INVOKABLE void start(QString program, QStringList arguments);
    Q_INVOKABLE void write(QString data);
    inline QString command() const { return m_command; }
    void setCommand(const QString &command);
    inline QString standardErrorFile() const { return m_errorFile; }
    void setStandardErrorFile(const QString &fileName);
    inline QString standardInputFile() const { return m_inputFile; }
    void setStandardInputFile(const QString &fileName);
    inline QString standardOutputFile() const { return m_outputFile; }
    void setStandardOutputFile(const QString &fileName);
    inline QDeclarativeProcess* standardOutputProcess() const { return m_outputProcess; }
    void setStandardOutputProcess(QDeclarativeProcess *destination);
    QVariantMap processEnvironment();
    void setProcessEnvironment(const QVariantMap &envMap);
    void setWorkingDirectory(const QString &dir);
    void setProcessChannelMode(QDeclarativeProcessEnums::ProcessChannelMode mode);
    void setReadChannel(QDeclarativeProcessEnums::ProcessChannel channel);
    QDeclarativeProcessEnums::ProcessError error() const;
    QDeclarativeProcessEnums::ProcessChannel readChannel() const;
    QDeclarativeProcessEnums::ProcessChannelMode processChannelMode() const;
    QDeclarativeProcessEnums::ExitStatus exitStatus() const;
    QDeclarativeProcessEnums::ProcessState state() const;

private slots:
    void onStateChanged(QProcess::ProcessState state);
    void onFinished(int exitCode, QProcess::ExitStatus exitStatus);

signals:
    void pidChanged();
    void errorChanged();
    void stateChanged(QDeclarativeProcessEnums::ProcessState state);
    void exitCodeChanged();
    void exitStatusChanged();
    void finished(int exitCode, QDeclarativeProcessEnums::ExitStatus exitStatus);
    void processFinished();
    void readyReadStandardError();
    void readyReadStandardOutput();
    void started();
    void commandChanged();
    void processEnvironmentChanged();
    void workingDirectoryChanged();
    
private:
    QString m_command;
    QString m_errorFile;
    QString m_inputFile;
    QString m_outputFile;
    QDeclarativeProcess* m_outputProcess;
};

#endif // QDECLARATIVEPROCESS_H
