#include <QtQuickTest/quicktest.h>

#include <QQmlEngine>
#include <QQmlContext>
#include <QTemporaryDir>

#include "database.h"
#include "appsettings.h"
#include "repository.h"
#include "itemmodel.h"
#include "inboxproxymodel.h"
#include "columnproxymodel.h"
#include "calendarmodel.h"
#include "listproxymodel.h"
#include "mapproxymodel.h"

class Setup : public QObject
{
    Q_OBJECT

public:
    Setup()
    {
        m_dir.setAutoRemove(true);
        m_dbPath = m_dir.filePath(QStringLiteral("qmltest.db"));
    }

public slots:
    void qmlEngineAvailable(QQmlEngine *engine)
    {
        if (!m_dbReady) {
            QString error;
            if (!db::open(m_dbPath, &error)) {
                qWarning("Gagal membuka db qmltest: %s", qPrintable(error));
                return;
            }
            if (!db::initSchema() || !db::seedDefaults()) {
                qWarning("Gagal menyiapkan skema qmltest");
                return;
            }
            m_dbReady = true;
        }

        if (!m_registered) {
            qmlRegisterType<ColumnProxyModel>("PetaIde", 1, 0, "ColumnProxyModel");
            qmlRegisterType<ListProxyModel>("PetaIde", 1, 0, "ListProxyModel");
            qmlRegisterType<CalendarProxyModel>("PetaIde", 1, 0, "CalendarProxyModel");
            qmlRegisterType<MapProxyModel>("PetaIde", 1, 0, "MapProxyModel");
            m_registered = true;
        }
        if (!m_itemModel) {
            m_itemModel = new ItemModel(&m_repo, this);
            m_inboxModel = new InboxProxyModel(m_itemModel, this);
        }

        engine->rootContext()->setContextProperty(QStringLiteral("appSettings"), &m_settings);
        engine->rootContext()->setContextProperty(QStringLiteral("repo"), &m_repo);
        engine->rootContext()->setContextProperty(QStringLiteral("itemModel"), m_itemModel);
        engine->rootContext()->setContextProperty(QStringLiteral("inboxModel"), m_inboxModel);
    }

private:
    QTemporaryDir m_dir;
    QString m_dbPath;
    bool m_dbReady = false;
    bool m_registered = false;
    AppSettings m_settings;
    Repository m_repo;
    ItemModel *m_itemModel = nullptr;
    InboxProxyModel *m_inboxModel = nullptr;
};

QUICK_TEST_MAIN_WITH_SETUP(tst_qml, Setup)
#include "tst_qml.moc"