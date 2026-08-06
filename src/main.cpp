#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QCommandLineParser>
#include <QDir>
#include <QLocale>
#include <QTranslator>

#include "appsettings.h"
#include "database.h"
#include "repository.h"
#include "itemmodel.h"
#include "inboxproxymodel.h"
#include "columnproxymodel.h"
#include "calendarmodel.h"
#include "listproxymodel.h"
#include "mapproxymodel.h"

static bool loadTranslation(QTranslator *translator, const QString &lang)
{
    if (!lang.isEmpty() && lang != QStringLiteral("auto")) {
        QString baseName = QStringLiteral("ToDoList-Integrated_") + lang;
        if (translator->load(QStringLiteral(":/i18n/") + baseName))
            return true;
        if (lang == QStringLiteral("id")) {
            baseName = QStringLiteral("ToDoList-Integrated_id_ID");
            if (translator->load(QStringLiteral(":/i18n/") + baseName))
                return true;
        }
    }
    const QStringList uiLanguages = QLocale::system().uiLanguages();
    for (const QString &locale : uiLanguages) {
        const QString baseName = QStringLiteral("ToDoList-Integrated_") + QLocale(locale).name();
        if (translator->load(QStringLiteral(":/i18n/") + baseName))
            return true;
    }
    return false;
}

int main(int argc, char *argv[])
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    QGuiApplication app(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("PetaIde"));

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("Peta Ide - pengelola Item dengan 5 view tersinkron"));
    parser.addHelpOption();
    QCommandLineOption dbOption(QStringLiteral("db"),
                                QStringLiteral("Path ke file database SQLite. Default: dekat executable."),
                                QStringLiteral("file"));
    parser.addOption(dbOption);
    parser.process(app);

    QString dbPath = parser.value(dbOption);
    if (dbPath.isEmpty())
        dbPath = QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("todo.db"));

    QString error;
    if (!db::open(dbPath, &error)) {
        qCritical("Gagal membuka database %s: %s", qPrintable(dbPath), qPrintable(error));
        return 1;
    }
    if (!db::initSchema()) {
        qCritical("Gagal membuat skema database");
        return 1;
    }
    db::seedDefaults();

    AppSettings settings;
    Repository repo;
    ItemModel itemModel(&repo);
    InboxProxyModel inboxModel(&itemModel);

    qmlRegisterType<ColumnProxyModel>("PetaIde", 1, 0, "ColumnProxyModel");
    qmlRegisterType<ListProxyModel>("PetaIde", 1, 0, "ListProxyModel");
    qmlRegisterType<CalendarProxyModel>("PetaIde", 1, 0, "CalendarProxyModel");
    qmlRegisterType<MapProxyModel>("PetaIde", 1, 0, "MapProxyModel");

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("appSettings"), &settings);
    engine.rootContext()->setContextProperty(QStringLiteral("repo"), &repo);
    engine.rootContext()->setContextProperty(QStringLiteral("itemModel"), &itemModel);
    engine.rootContext()->setContextProperty(QStringLiteral("inboxModel"), &inboxModel);

    QTranslator *translator = new QTranslator(&app);
    app.installTranslator(translator);
    loadTranslation(translator, settings.language());
    QObject::connect(&settings, &AppSettings::languageChanged, &app, [&engine, &settings, translator]() {
        loadTranslation(translator, settings.language());
        engine.retranslate();
    });

    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}