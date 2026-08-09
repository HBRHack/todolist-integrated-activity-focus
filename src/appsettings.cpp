#include "appsettings.h"

#include "database.h"

#include <QSqlQuery>
#include <QVariant>

AppSettings::AppSettings(QObject *parent)
    : QObject(parent)
{
}

QString AppSettings::theme() const
{
    return value(QStringLiteral("theme"), QStringLiteral("light"));
}

void AppSettings::setTheme(const QString &value)
{
    if (value == theme())
        return;
    setValue(QStringLiteral("theme"), value);
    emit themeChanged();
}

QString AppSettings::inboxMode() const
{
    return value(QStringLiteral("inbox_mode"), QStringLiteral("global"));
}

void AppSettings::setInboxMode(const QString &value)
{
    if (value == inboxMode())
        return;
    setValue(QStringLiteral("inbox_mode"), value);
    emit inboxModeChanged();
}

QString AppSettings::mapMode() const
{
    return value(QStringLiteral("map_mode"), QStringLiteral("global"));
}

void AppSettings::setMapMode(const QString &value)
{
    setValue(QStringLiteral("map_mode_chosen"), QStringLiteral("1"));
    emit mapModeChosenChanged();
    if (value == mapMode())
        return;
    setValue(QStringLiteral("map_mode"), value);
    emit mapModeChanged();
}

bool AppSettings::mapModeChosen() const
{
    return value(QStringLiteral("map_mode_chosen"), QStringLiteral("0")) == QStringLiteral("1");
}

void AppSettings::resetMapModeChosen()
{
    if (!mapModeChosen())
        return;
    setValue(QStringLiteral("map_mode_chosen"), QStringLiteral("0"));
    emit mapModeChosenChanged();
}

QString AppSettings::language() const
{
    return value(QStringLiteral("language"), QStringLiteral("auto"));
}

void AppSettings::setLanguage(const QString &value)
{
    if (value == language())
        return;
    setValue(QStringLiteral("language"), value);
    emit languageChanged();
}

bool AppSettings::canvasLocked() const
{
    return value(QStringLiteral("canvas_locked"), QStringLiteral("0"))
        == QStringLiteral("1");
}

void AppSettings::setCanvasLocked(bool locked)
{
    if (locked == canvasLocked())
        return;
    setValue(QStringLiteral("canvas_locked"), locked ? QStringLiteral("1")
                                                       : QStringLiteral("0"));
    emit canvasLockedChanged();
}

QString AppSettings::value(const QString &key, const QString &fallback) const
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral("SELECT value FROM app_settings WHERE key = :k"));
    q.bindValue(QStringLiteral(":k"), key);
    if (!q.exec() || !q.next())
        return fallback;
    return q.value(0).toString();
}

void AppSettings::setValue(const QString &key, const QString &value)
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral(
        "INSERT INTO app_settings (key, value) VALUES (:k, :v) "
        "ON CONFLICT(key) DO UPDATE SET value = excluded.value"));
    q.bindValue(QStringLiteral(":k"), key);
    q.bindValue(QStringLiteral(":v"), value);
    q.exec();
}
