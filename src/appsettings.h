#pragma once

#include <QObject>
#include <QString>

class AppSettings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString theme READ theme WRITE setTheme NOTIFY themeChanged)
    Q_PROPERTY(QString inboxMode READ inboxMode WRITE setInboxMode NOTIFY inboxModeChanged)
    Q_PROPERTY(QString mapMode READ mapMode WRITE setMapMode NOTIFY mapModeChanged)
    Q_PROPERTY(bool mapModeChosen READ mapModeChosen NOTIFY mapModeChosenChanged)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)
    Q_PROPERTY(bool canvasLocked READ canvasLocked WRITE setCanvasLocked NOTIFY canvasLockedChanged)

public:
    explicit AppSettings(QObject *parent = nullptr);

    QString theme() const;
    void setTheme(const QString &value);

    QString inboxMode() const;
    void setInboxMode(const QString &value);

    QString mapMode() const;
    void setMapMode(const QString &value);

    bool mapModeChosen() const;
    Q_INVOKABLE void resetMapModeChosen();

    QString language() const;
    void setLanguage(const QString &value);

    bool canvasLocked() const;
    void setCanvasLocked(bool locked);

signals:
    void themeChanged();
    void inboxModeChanged();
    void mapModeChanged();
    void mapModeChosenChanged();
    void languageChanged();
    void canvasLockedChanged();

private:
    QString value(const QString &key, const QString &fallback) const;
    void setValue(const QString &key, const QString &value);
};
