#include <QtTest>
#include <QTemporaryDir>
#include <QFile>
#include <QSet>
#include <algorithm>

#include "database.h"
#include "appsettings.h"
#include "repository.h"
#include "dateparser.h"
#include "itemmodel.h"
#include "inboxproxymodel.h"
#include "columnproxymodel.h"
#include "calendarmodel.h"
#include "listproxymodel.h"
#include "mapproxymodel.h"
#include "nodelayout.h"

static QDate nextMonday(const QDate &base)
{
    int diff = (1 - base.dayOfWeek() + 7) % 7;
    if (diff == 0)
        diff = 7;
    return base.addDays(diff);
}

static QDate prevMonday(const QDate &base)
{
    int diff = (base.dayOfWeek() - 1 + 7) % 7;
    if (diff == 0)
        diff = 7;
    return base.addDays(-diff);
}

static QDate nextTuesday(const QDate &base)
{
    for (int i = 1; i <= 7; ++i) {
        const QDate d = base.addDays(i);
        if (d.dayOfWeek() == Qt::Tuesday)
            return d;
    }
    return base;
}

class TstBackend : public QObject
{
    Q_OBJECT

private slots:
    void init();
    void schemaIsV4();
    void seedCreatesUmumBoard();
    void settingsPersistAcrossReopen();
    void repositoryColumnCrud();
    void columnColorPersists();
    void columnColorInvalidKeyFallsBackToAccent();
    void columnReorder();
    void boardCrudAndDeleteSemantics();
    void itemCrudAndMapping();
    void dragBetweenColumnsUpdatesOrder();
    void reorderWithinColumnFinalIndex();
    void firstMappingSetsLastMappedAtOnce();
    void columnProxyReflectsMotion();
    void moveToInboxKeepsColumnOrder();
    void quickAddDefaultsToToday();
    void nlpParsesLikeQuickAdd();
    void nlpManualDateOverride();
    void addItemInvalidDueDefaultsToToday();
    void inboxGroupingViaModels();
    void inboxProxyPerBoardFilter();
    void listProxyFiltersByBoard();
    void listProxySortsByDateAndStatus();
    void calendarProxyFiltersByMonth();
    void nodePositionRoundtrip();
    void nodePositionPersistsAcrossReopen();
    void mapProxyFiltersByBoard();
    void edgeCrudRoundtrip();
    void edgePersistsAcrossReopen();
    void shapeCrudRoundtrip();
    void shapeGlobalVsBoardFilter();
    void shapePersistsAcrossReopen();
    void boardDeleteCascadesShapes();
    void convertShapeToEntityRoundtrip();
    void itemDeleteUnlinksShape();
    void dateParserGrammar();
    void nodeLayoutProducesLevelsWithoutOverlap();
    void nodeLayoutPersistsPositionsViaRepo();
    void cleanup();

private:
    QTemporaryDir dir;
    QString path;
};

void TstBackend::init()
{
    QVERIFY(dir.isValid());
    path = dir.filePath(QStringLiteral("test.db"));
    QFile::remove(path); // instance dipakai ulang antar test — pastikan DB bersih
    QString error;
    QVERIFY2(db::open(path, &error), qPrintable(error));
    QVERIFY(db::initSchema());
    QVERIFY(db::seedDefaults());
}

void TstBackend::schemaIsV4()
{
    QCOMPARE(db::schemaVersion(), 4);
}

void TstBackend::seedCreatesUmumBoard()
{
    Repository repo;
    const auto boards = repo.boards();
    QCOMPARE(boards.size(), 1);
    QCOMPARE(boards.first().name, QStringLiteral("Umum"));

    const auto cols = repo.columnsForBoard(boards.first().id);
    QCOMPARE(cols.size(), 3);
    QCOMPARE(cols.at(0).name, QStringLiteral("To Do"));
    QCOMPARE(cols.at(1).name, QStringLiteral("In Progress"));
    QCOMPARE(cols.at(2).name, QStringLiteral("Done"));
}

void TstBackend::settingsPersistAcrossReopen()
{
    AppSettings s;
    s.setTheme(QStringLiteral("dark"));
    s.setInboxMode(QStringLiteral("perboard"));
    QCOMPARE(s.theme(), QStringLiteral("dark"));
    QCOMPARE(s.inboxMode(), QStringLiteral("perboard"));

    db::close();
    QString error;
    QVERIFY2(db::open(path, &error), qPrintable(error));
    QVERIFY(db::initSchema());

    AppSettings s2;
    QCOMPARE(s2.theme(), QStringLiteral("dark"));
    QCOMPARE(s2.inboxMode(), QStringLiteral("perboard"));
}

void TstBackend::repositoryColumnCrud()
{
    Repository repo;
    const int boardId = repo.boards().first().id;

    const int colId = repo.addColumn(boardId, QStringLiteral("Backlog"));
    QVERIFY(colId > 0);
    QCOMPARE(repo.columnsForBoard(boardId).size(), 4);

    repo.renameColumn(colId, QStringLiteral("Tunda"));
    auto cols = repo.columnsForBoard(boardId);
    QCOMPARE(cols.at(3).name, QStringLiteral("Tunda"));

    repo.deleteColumn(colId);
    QCOMPARE(repo.columnsForBoard(boardId).size(), 3);
}

void TstBackend::columnColorPersists()
{
    Repository repo;
    const int boardId = repo.boards().first().id;

    const int colId = repo.addColumn(boardId, QStringLiteral("Backlog"));
    QVERIFY(colId > 0);

    auto colorOf = [&repo](int id) {
        const auto all = repo.columnsForBoard(repo.boards().first().id);
        for (const Column &c : all)
            if (c.id == id)
                return c.colorKey;
        return QString();
    };

    QCOMPARE(colorOf(colId), QStringLiteral("accent"));

    repo.setColumnColor(colId, QStringLiteral("danger"));
    QCOMPARE(colorOf(colId), QStringLiteral("danger"));

    QVariantList list = repo.columnList(boardId);
    bool found = false;
    for (const QVariant &v : list) {
        const QVariantMap m = v.toMap();
        if (m.value(QStringLiteral("id")).toInt() == colId) {
            QCOMPARE(m.value(QStringLiteral("colorKey")).toString(), QStringLiteral("danger"));
            found = true;
        }
    }
    QVERIFY2(found, "kolom yang diwarnai tidak ada di columnList");
}

void TstBackend::columnColorInvalidKeyFallsBackToAccent()
{
    Repository repo;
    const int boardId = repo.boards().first().id;
    const int colId = repo.addColumn(boardId, QStringLiteral("Backlog"));

    QSignalSpy spy(&repo, &Repository::changed);
    repo.setColumnColor(colId, QStringLiteral("ungu-aneh"));

    QCOMPARE(spy.count(), 1);

    const auto all = repo.columnsForBoard(boardId);
    auto it = std::find_if(all.cbegin(), all.cend(), [colId](const Column &c) { return c.id == colId; });
    QVERIFY(it != all.cend());
    QCOMPARE(it->colorKey, QStringLiteral("accent"));
}

void TstBackend::columnReorder()
{
    Repository repo;
    const int boardId = repo.boards().first().id;
    const int c1 = repo.columnsForBoard(boardId).at(0).id;
    const int c3 = repo.columnsForBoard(boardId).at(2).id;

    repo.moveColumn(boardId, c3, 0);
    auto cols = repo.columnsForBoard(boardId);
    QCOMPARE(cols.at(0).id, c3);
    QCOMPARE(cols.at(1).id, c1);

    repo.moveColumn(boardId, c3, 10);
    cols = repo.columnsForBoard(boardId);
    QCOMPARE(cols.at(2).id, c3);
}

void TstBackend::boardCrudAndDeleteSemantics()
{
    Repository repo;
    const int boardId = repo.boards().first().id;
    const int colId = repo.columnsForBoard(boardId).first().id;

    const int itemA = repo.addItem(QStringLiteral("A"), QString(), QDate::currentDate());
    repo.moveItem(itemA, colId, 0);

    const int boardB = repo.addBoard(QStringLiteral("Proyek B"));
    QVERIFY(boardB > 0);
    repo.renameBoard(boardB, QStringLiteral("Proyek C"));
    bool renamed = false;
    for (const Board &b : repo.boards())
        if (b.id == boardB && b.name == QStringLiteral("Proyek C"))
            renamed = true;
    QVERIFY(renamed);

    // Hapus kolom → item balik ke Inbox (data tidak terhapus)
    const int colB = repo.addColumn(boardB, QStringLiteral("Kolom B"));
    const int itemB = repo.addItem(QStringLiteral("B"), QString(), QDate::currentDate(), QTime(), colB);
    repo.deleteColumn(colB);
    bool bBackInInbox = false;
    for (const ItemData &it : repo.items())
        if (it.id == itemB && it.columnId == -1 && it.title == QStringLiteral("B"))
            bBackInInbox = true;
    QVERIFY(bBackInInbox);

    // Hapus board → seluruh itemnya balik ke Inbox
    const int colB2 = repo.addColumn(boardB, QStringLiteral("Kolom B2"));
    repo.moveItem(itemB, colB2, 0);
    repo.deleteBoard(boardB);
    bool bStillInInbox = false;
    bool aIntact = false;
    for (const ItemData &it : repo.items()) {
        if (it.id == itemB && it.columnId == -1)
            bStillInInbox = true;
        if (it.id == itemA && it.columnId == colId)
            aIntact = true;
    }
    QVERIFY(bStillInInbox);
    QVERIFY(aIntact);

    for (const Board &b : repo.boards())
        QVERIFY(b.id != boardB);
}

void TstBackend::itemCrudAndMapping()
{
    Repository repo;
    const int boardId = repo.boards().first().id;
    const int colId = repo.columnsForBoard(boardId).first().id;

    const QDate today = QDate::currentDate();
    const int itemId = repo.addItem(QStringLiteral("beli susu"), QString(), today);
    QVERIFY(itemId > 0);

    auto items = repo.items();
    QCOMPARE(items.size(), 1);
    QCOMPARE(items.first().title, QStringLiteral("beli susu"));
    QCOMPARE(items.first().dueDate, today);
    QCOMPARE(items.first().columnId, -1);
    QVERIFY(!items.first().lastMappedAt.isValid());

    repo.updateItem(itemId, QStringLiteral("beli susu cair"), QStringLiteral("full cream"));
    items = repo.items();
    QCOMPARE(items.first().title, QStringLiteral("beli susu cair"));
    QCOMPARE(items.first().description, QStringLiteral("full cream"));
    // updateItem tanpa tanggal → due date dipertahankan (COALESCE)
    QCOMPARE(items.first().dueDate, today);

    // updateItem dengan tanggal → koreksi tebakan parser (spec story 4 / ADR-0003)
    repo.updateItem(itemId, QStringLiteral("beli susu cair"), QStringLiteral("full cream"),
                    today.addDays(3));
    items = repo.items();
    QCOMPARE(items.first().dueDate, today.addDays(3));

    repo.moveItem(itemId, colId, 0);
    items = repo.items();
    QCOMPARE(items.first().columnId, colId);
    QVERIFY(items.first().lastMappedAt.isValid());

    repo.rescheduleItem(itemId, today.addDays(2));
    items = repo.items();
    QCOMPARE(items.first().dueDate, today.addDays(2));

    repo.deleteItem(itemId);
    QCOMPARE(repo.items().size(), 0);
}

void TstBackend::dragBetweenColumnsUpdatesOrder()
{
    Repository repo;
    const int boardId = repo.boards().first().id;
    const int colA = repo.columnsForBoard(boardId).at(0).id;
    const int colB = repo.columnsForBoard(boardId).at(1).id;

    const int a = repo.addItem(QStringLiteral("a"), QString(), QDate::currentDate());
    const int b = repo.addItem(QStringLiteral("b"), QString(), QDate::currentDate());
    const int c = repo.addItem(QStringLiteral("c"), QString(), QDate::currentDate());
    for (int id : { a, b, c })
        repo.moveItem(id, colA, 99);

    auto seqOf = [&](int col) {
        QStringList seq;
        for (const ItemData &it : repo.items())
            if (it.columnId == col)
                seq.append(it.title);
        return seq;
    };
    QCOMPARE(seqOf(colA), QStringList({ QStringLiteral("a"), QStringLiteral("b"), QStringLiteral("c") }));

    // Seret "b" (index 1) ke kolom B pada posisi 0 → [a,c] di A, [b] di B
    repo.moveItem(b, colB, 0);
    QCOMPARE(seqOf(colA), QStringList({ QStringLiteral("a"), QStringLiteral("c") }));
    QCOMPARE(seqOf(colB), QStringList({ QStringLiteral("b") }));

    // order_index ternormalisasi 0..n di kedua kolom
    bool normalized = true;
    for (const ItemData &it : repo.items())
        if (it.orderIndex < 0)
            normalized = false;
    QVERIFY(normalized);

    // "c" kembali ke kolom A: clamp index negatif ke 0 → [c,b] di B, [a] di A
    repo.moveItem(c, colB, -1);
    QCOMPARE(seqOf(colB), QStringList({ QStringLiteral("c"), QStringLiteral("b") }));
    repo.moveItem(c, colA, 0);
    QCOMPARE(seqOf(colA), QStringList({ QStringLiteral("c"), QStringLiteral("a") }));
}

void TstBackend::reorderWithinColumnFinalIndex()
{
    Repository repo;
    const int boardId = repo.boards().first().id;
    const int colA = repo.columnsForBoard(boardId).at(0).id;

    const int a = repo.addItem(QStringLiteral("a"), QString(), QDate::currentDate());
    const int b = repo.addItem(QStringLiteral("b"), QString(), QDate::currentDate());
    const int c = repo.addItem(QStringLiteral("c"), QString(), QDate::currentDate());
    for (int id : { a, b, c })
        repo.moveItem(id, colA, 99);

    auto orderOf = [&]() {
        QStringList seq;
        for (const ItemData &it : repo.items())
            if (it.columnId == colA)
                seq.append(it.title);
        return seq;
    };

    // "b" (index 1) → posisi final 2 (akhir) → [a,c,b]
    repo.moveItem(b, colA, 2);
    QCOMPARE(orderOf(), QStringList({ QStringLiteral("a"), QStringLiteral("c"), QStringLiteral("b") }));

    // "a" (index 0) → posisi final 1 → [c,a,b]
    repo.moveItem(a, colA, 1);
    QCOMPARE(orderOf(), QStringList({ QStringLiteral("c"), QStringLiteral("a"), QStringLiteral("b") }));

    // Index melewati batas → clamp ke akhir
    repo.moveItem(a, colA, 99);
    QCOMPARE(orderOf(), QStringList({ QStringLiteral("c"), QStringLiteral("b"), QStringLiteral("a") }));

    // order_index bernilai 0..n-1 berurutan
    QSet<int> seen;
    for (const ItemData &it : repo.items())
        if (it.columnId == colA)
            seen.insert(it.orderIndex);
    QCOMPARE(seen, QSet<int>({ 0, 1, 2 }));
}

void TstBackend::firstMappingSetsLastMappedAtOnce()
{
    Repository repo;
    const int boardId = repo.boards().first().id;
    const int colA = repo.columnsForBoard(boardId).at(0).id;

    const int a = repo.addItem(QStringLiteral("a"), QString(), QDate::currentDate());
    QVERIFY(!repo.items().first().lastMappedAt.isValid());

    // Pemetaan pertama → last_mapped_at terisi
    repo.moveItem(a, colA, 0);
    const QDateTime firstMapped = repo.items().first().lastMappedAt;
    QVERIFY(firstMapped.isValid());

    // Reorder dalam kolom → last_mapped_at tidak berubah
    const int b = repo.addItem(QStringLiteral("b"), QString(), QDate::currentDate());
    repo.moveItem(b, colA, 0);
    QCOMPARE(repo.items().at(1).lastMappedAt, firstMapped);

    // Pindah kolom lain → tetap dipertahankan
    const int colB = repo.columnsForBoard(boardId).at(1).id;
    repo.moveItem(a, colB, 0);
    for (const ItemData &it : repo.items())
        if (it.id == a)
            QCOMPARE(it.lastMappedAt, firstMapped);
}

void TstBackend::columnProxyReflectsMotion()
{
    Repository repo;
    const int boardId = repo.boards().first().id;
    const int colA = repo.columnsForBoard(boardId).at(0).id;
    const int colB = repo.columnsForBoard(boardId).at(1).id;

    ItemModel model(&repo);
    ColumnProxyModel proxyA;
    proxyA.setColumnId(colA);
    proxyA.setSourceModel(&model);
    QCoreApplication::processEvents();

    const int a = repo.addItem(QStringLiteral("a"), QString(), QDate::currentDate());
    const int b = repo.addItem(QStringLiteral("b"), QString(), QDate::currentDate());
    repo.moveItem(a, colA, 99);
    repo.moveItem(b, colA, 99);
    QCoreApplication::processEvents();
    QCOMPARE(proxyA.rowCount(), 2);
    QCOMPARE(proxyA.index(0, 0).data(ItemModel::TitleRole).toString(), QStringLiteral("a"));
    QCOMPARE(proxyA.index(1, 0).data(ItemModel::TitleRole).toString(), QStringLiteral("b"));

    // Reorder di dalam kolom → urutan proxy ikut berubah tanpa refresh manual
    repo.moveItem(a, colA, 1);
    QCoreApplication::processEvents();
    QCOMPARE(proxyA.index(0, 0).data(ItemModel::TitleRole).toString(), QStringLiteral("b"));
    QCOMPARE(proxyA.index(1, 0).data(ItemModel::TitleRole).toString(), QStringLiteral("a"));

    // Pindah antar kolom → hilang dari proxy A, muncul di proxy B
    ColumnProxyModel proxyB;
    proxyB.setColumnId(colB);
    proxyB.setSourceModel(&model);
    repo.moveItem(a, colB, 0);
    QCoreApplication::processEvents();
    QCOMPARE(proxyA.rowCount(), 1);
    QCOMPARE(proxyB.rowCount(), 1);
    QCOMPARE(proxyB.index(0, 0).data(ItemModel::TitleRole).toString(), QStringLiteral("a"));
}

void TstBackend::moveToInboxKeepsColumnOrder()
{
    Repository repo;
    const int boardId = repo.boards().first().id;
    const int colA = repo.columnsForBoard(boardId).at(0).id;

    const int a = repo.addItem(QStringLiteral("a"), QString(), QDate::currentDate());
    const int b = repo.addItem(QStringLiteral("b"), QString(), QDate::currentDate());
    const int c = repo.addItem(QStringLiteral("c"), QString(), QDate::currentDate());
    for (int id : { a, b, c })
        repo.moveItem(id, colA, 99);

    // "b" kembali ke Inbox → kolom tersisa tetap [a,c] dengan order 0,1
    repo.moveItem(b, -1, 0);
    QStringList seq;
    for (const ItemData &it : repo.items()) {
        if (it.columnId == colA)
            seq.append(it.title);
        else if (it.id == b)
            QCOMPARE(it.columnId, -1);
    }
    QCOMPARE(seq, QStringList({ QStringLiteral("a"), QStringLiteral("c") }));
    for (const ItemData &it : repo.items())
        if (it.columnId == colA)
            QVERIFY(it.orderIndex >= 0 && it.orderIndex <= 1);
}

void TstBackend::quickAddDefaultsToToday()
{
    Repository repo;
    const int id = repo.quickAdd(QStringLiteral("beli susu"));
    QVERIFY(id > 0);
    auto items = repo.items();
    QCOMPARE(items.size(), 1);
    QCOMPARE(items.first().id, id);
    QCOMPARE(items.first().dueDate, QDate::currentDate());
    QCOMPARE(items.first().columnId, -1);
    QVERIFY(!items.first().lastMappedAt.isValid());

    // Quick-add dengan tanggal → due date terisi, title dibersihkan
    const int id2 = repo.quickAdd(QStringLiteral("beli susu besok"));
    items = repo.items();
    for (const ItemData &it : items) {
        if (it.id == id2) {
            QCOMPARE(it.dueDate, QDate::currentDate().addDays(1));
            QCOMPARE(it.title, QStringLiteral("beli susu"));
        }
    }
}

void TstBackend::nlpParsesLikeQuickAdd()
{
    Repository repo;
    const QVariantMap parsed = repo.parseNlp(QStringLiteral("rapat senin jam 9"));
    QVERIFY(parsed.value(QStringLiteral("detected")).toBool());
    QCOMPARE(parsed.value(QStringLiteral("cleanTitle")).toString(), QStringLiteral("rapat"));
    QCOMPARE(parsed.value(QStringLiteral("dueDate")).toString(),
             nextMonday(QDate::currentDate()).toString(Qt::ISODate));
    QCOMPARE(parsed.value(QStringLiteral("dueTime")).toString(), QStringLiteral("09:00"));

    const QVariantMap plain = repo.parseNlp(QStringLiteral("catat tanpa tanggal"));
    QVERIFY(!plain.value(QStringLiteral("detected")).toBool());
    QCOMPARE(plain.value(QStringLiteral("cleanTitle")).toString(),
             QStringLiteral("catat tanpa tanggal"));

    const int id = repo.addItemNlp(QStringLiteral("beli susu besok"),
                                   QStringLiteral("2 liter"), QString());
    const auto items = repo.items();
    for (const ItemData &it : items) {
        if (it.id == id) {
            QCOMPARE(it.title, QStringLiteral("beli susu"));
            QCOMPARE(it.dueDate, QDate::currentDate().addDays(1));
            QCOMPARE(it.description, QStringLiteral("2 liter"));
            QCOMPARE(it.columnId, -1);
        }
    }
}

void TstBackend::nlpManualDateOverride()
{
    Repository repo;
    QVERIFY(repo.addItemNlp(QStringLiteral("jual garam besok"),
                            QString(), QStringLiteral("2024-12-15")) > 0);
    const auto items = repo.items();
    QCOMPARE(items.size(), 1);
    QCOMPARE(items.first().title, QStringLiteral("jual garam"));
    QCOMPARE(items.first().dueDate, QDate(2024, 12, 15));
}

void TstBackend::addItemInvalidDueDefaultsToToday()
{
    Repository repo;
    // spec story 3: setiap Item selalu punya tanggal due valid
    const int id = repo.addItem(QStringLiteral("tanpa tanggal"), QString(), QDate());
    QVERIFY(id > 0);
    auto items = repo.items();
    bool found = false;
    for (const ItemData &it : items) {
        if (it.id == id) {
            found = true;
            QCOMPARE(it.dueDate, QDate::currentDate());
        }
    }
    QVERIFY(found);

    repo.deleteItem(id);
    // tidak boleh ada item NoDate yang tersisa (story 3)
    for (const ItemData &it : repo.items())
        QVERIFY(it.dueDate.isValid());
}

void TstBackend::inboxGroupingViaModels()
{
    Repository repo;
    const int boardId = repo.boards().first().id;
    const int colId = repo.columnsForBoard(boardId).first().id;

    ItemModel model(&repo);
    InboxProxyModel inbox(&model);
    QCoreApplication::processEvents();
    QCOMPARE(inbox.rowCount(), 0);

    const int itemId = repo.quickAdd(QStringLiteral("beli susu besok"));
    QCoreApplication::processEvents();
    QCOMPARE(inbox.rowCount(), 1);
    QCOMPARE(inbox.index(0, 0).data(ItemModel::GroupRole).toString(), QStringLiteral("baru"));

    // Dipetakan → keluar Inbox
    repo.moveItem(itemId, colId, 0);
    QCoreApplication::processEvents();
    QCOMPARE(inbox.rowCount(), 0);

    // Dikembalikan ke Inbox → group "dikembalikan" via last_mapped_at
    repo.moveItem(itemId, -1, 0);
    QCoreApplication::processEvents();
    QCOMPARE(inbox.rowCount(), 1);
    QCOMPARE(inbox.index(0, 0).data(ItemModel::GroupRole).toString(), QStringLiteral("dikembalikan"));
}

void TstBackend::inboxProxyPerBoardFilter()
{
    Repository repo;
    const int boardA = repo.boards().first().id;
    const int colA = repo.columnsForBoard(boardA).first().id;
    const int boardB = repo.addBoard(QStringLiteral("Inbox B"));
    const int colB = repo.addColumn(boardB, QStringLiteral("Kolom B"));

    ItemModel model(&repo);
    InboxProxyModel inbox(&model);
    QCoreApplication::processEvents();

    const int fresh = repo.quickAdd(QStringLiteral("belum dipetakan"));
    QCoreApplication::processEvents();
    QCOMPARE(inbox.rowCount(), 1);

    const int backA = repo.quickAdd(QStringLiteral("kembali ke A"));
    repo.moveItem(backA, colA, 0);
    QCoreApplication::processEvents();
    QCOMPARE(inbox.rowCount(), 1);

    repo.moveItem(backA, -1, 0);
    QCoreApplication::processEvents();
    QCOMPARE(inbox.rowCount(), 2);

    // Per-Board, tab board A → hanya item asal board A (board_id dipertahankan)
    inbox.setPerBoard(true);
    inbox.setBoardId(boardA);
    QCoreApplication::processEvents();
    QCOMPARE(inbox.rowCount(), 1);
    QCOMPARE(inbox.index(0, 0).data(ItemModel::IdRole).toInt(), backA);

    // Tab board B → belum ada item asal board B
    inbox.setBoardId(boardB);
    QCoreApplication::processEvents();
    QCOMPARE(inbox.rowCount(), 0);

    // Tab "Semua" (−1) → seluruh item belum dipetakan
    inbox.setBoardId(-1);
    QCoreApplication::processEvents();
    QCOMPARE(inbox.rowCount(), 2);

    // Mode global → semua item belum dipetakan
    inbox.setPerBoard(false);
    QCoreApplication::processEvents();
    QCOMPARE(inbox.rowCount(), 2);
}

void TstBackend::listProxyFiltersByBoard()
{
    Repository repo;
    const int boardA = repo.boards().first().id;
    const int colA = repo.columnsForBoard(boardA).first().id;
    const int boardB = repo.addBoard(QStringLiteral("List B"));
    const int colB = repo.addColumn(boardB, QStringLiteral("Kolom B"));

    const int inA = repo.addItem(QStringLiteral("A"), QString(), QDate::currentDate());
    const int inB = repo.addItem(QStringLiteral("B"), QString(), QDate::currentDate());
    const int inInbox = repo.addItem(QStringLiteral("inbox"), QString(), QDate::currentDate());
    repo.moveItem(inA, colA, 0);
    repo.moveItem(inB, colB, 0);

    ItemModel model(&repo);
    ListProxyModel proxy;
    proxy.setItemModel(&model);
    QCoreApplication::processEvents();

    auto idsOf = [&]() {
        QList<int> out;
        for (int r = 0; r < proxy.rowCount(); ++r)
            out.append(proxy.index(r, 0).data(ItemModel::IdRole).toInt());
        return out;
    };

    // boardId -1 → semua Item termasuk yang di Inbox
    proxy.setBoardId(-1);
    QCoreApplication::processEvents();
    QCOMPARE(proxy.rowCount(), 3);
    QCOMPARE(proxy.property("count").toInt(), 3);
    QSet<int> allIds;
    for (int id : idsOf())
        allIds.insert(id);
    QCOMPARE(allIds, QSet<int>({ inA, inB, inInbox }));

    // Filter per board → hanya milik board tsb
    proxy.setBoardId(boardA);
    QCoreApplication::processEvents();
    QCOMPARE(proxy.rowCount(), 1);
    QCOMPARE(proxy.index(0, 0).data(ItemModel::IdRole).toInt(), inA);

    proxy.setBoardId(boardB);
    QCoreApplication::processEvents();
    QCOMPARE(proxy.rowCount(), 1);
    QCOMPARE(proxy.index(0, 0).data(ItemModel::IdRole).toInt(), inB);

    // Board tanpa Item → kosong
    const int emptyBoard = repo.addBoard(QStringLiteral("List Kosong"));
    proxy.setBoardId(emptyBoard);
    QCoreApplication::processEvents();
    QCOMPARE(proxy.rowCount(), 0);
    QCOMPARE(proxy.property("count").toInt(), 0);
}

void TstBackend::listProxySortsByDateAndStatus()
{
    Repository repo;
    const int boardA = repo.boards().first().id;
    const int colA = repo.columnsForBoard(boardA).at(0).id;
    const int colB = repo.columnsForBoard(boardA).at(1).id;

    const QDate today = QDate::currentDate();
    const int late = repo.addItem(QStringLiteral("lusa"), QString(), today.addDays(2));
    const int soon = repo.addItem(QStringLiteral("besok"), QString(), today.addDays(1));
    const int nowItem = repo.addItem(QStringLiteral("hari ini"), QString(), today);

    ItemModel model(&repo);
    ListProxyModel proxy;
    proxy.setItemModel(&model);
    QCoreApplication::processEvents();

    auto idsOf = [&]() {
        QList<int> out;
        for (int r = 0; r < proxy.rowCount(); ++r)
            out.append(proxy.index(r, 0).data(ItemModel::IdRole).toInt());
        return out;
    };

    // Sort "tanggal": dueDate naik (spec story 3 — tidak ada lagi item tanpa tanggal)
    proxy.setSortMode(QStringLiteral("tanggal"));
    QCoreApplication::processEvents();
    QCOMPARE(idsOf(), QList<int>({ nowItem, soon, late }));

    // Sort "status": Inbox (boardId -1) dulu, lalu board → kolom → orderIndex
    repo.moveItem(nowItem, colA, 0);
    repo.moveItem(soon, colA, 1);
    repo.moveItem(late, colB, 0);
    proxy.setSortMode(QStringLiteral("status"));
    QCoreApplication::processEvents();
    QCOMPARE(idsOf(), QList<int>({ nowItem, soon, late }));
}

void TstBackend::calendarProxyFiltersByMonth()
{
    Repository repo;
    const QDate today = QDate::currentDate();
    const QDate inDate = QDate(today.year(), today.month(), 15);
    const QDate outDate = inDate.addMonths(1);

    const int in = repo.addItem(QStringLiteral("dalam bulan ini"), QString(), inDate);
    const int out = repo.addItem(QStringLiteral("bulan lain"), QString(), outDate);

    ItemModel model(&repo);
    CalendarProxyModel proxy;
    proxy.setItemModel(&model);
    QCoreApplication::processEvents();

    // Bulan aktif = bulan item "dalam bulan ini"
    proxy.setYear(inDate.year());
    proxy.setMonth(inDate.month());
    QCoreApplication::processEvents();
    QCOMPARE(proxy.rowCount(), 1);
    QCOMPARE(proxy.index(0, 0).data(ItemModel::IdRole).toInt(), in);
    QCOMPARE(proxy.property("count").toInt(), 1);

    // itemsForDate mengembalikan item sesuai tanggal persis
    const auto hits = proxy.itemsForDate(inDate.year(), inDate.month(), inDate.day());
    QCOMPARE(hits.size(), 1);
    QCOMPARE(hits.first().toMap().value(QStringLiteral("itemId")).toInt(), in);
    QCOMPARE(proxy.itemsForDate(inDate.year(), inDate.month(), inDate.day() + 1).size(), 0);

    // Ganti bulan → item bulan sebelumnya keluar, item bulan lain masuk
    proxy.setYear(outDate.year());
    proxy.setMonth(outDate.month());
    QCoreApplication::processEvents();
    QCOMPARE(proxy.rowCount(), 1);
    QCOMPARE(proxy.index(0, 0).data(ItemModel::IdRole).toInt(), out);

    // Spec story 3 — setiap item via API sudah punya tanggal valid:
    // itemsWithoutDate selamanya 0 untuk data baru
    QCOMPARE(proxy.itemsWithoutDate(), 0);
}

void TstBackend::nodePositionRoundtrip()
{
    Repository repo;
    const int itemId = repo.addItem(QStringLiteral("node"), QString(), QDate::currentDate());
    QVERIFY(itemId > 0);

    QVERIFY(!repo.hasNodePosition(itemId));
    QVERIFY(repo.nodePosition(itemId).isNull());

    repo.setNodePosition(itemId, QPointF(123.5, 456.25));
    QVERIFY(repo.hasNodePosition(itemId));
    QCOMPARE(repo.nodePosition(itemId), QPointF(123.5, 456.25));

    // Item tanpa posisi tetap tanpa posisi
    const int otherId = repo.addItem(QStringLiteral("lain"), QString(), QDate::currentDate());
    QVERIFY(!repo.hasNodePosition(otherId));

    // Set ulang menimpa posisi lama
    repo.setNodePosition(itemId, QPointF(10.0, 20.0));
    QCOMPARE(repo.nodePosition(itemId), QPointF(10.0, 20.0));
}

void TstBackend::nodePositionPersistsAcrossReopen()
{
    Repository repo;
    const int itemId = repo.addItem(QStringLiteral("node"), QString(), QDate::currentDate());
    repo.setNodePosition(itemId, QPointF(77.25, 88.5));

    db::close();
    QString error;
    QVERIFY2(db::open(path, &error), qPrintable(error));
    QVERIFY(db::initSchema());

    Repository repo2;
    QVERIFY(repo2.hasNodePosition(itemId));
    QCOMPARE(repo2.nodePosition(itemId), QPointF(77.25, 88.5));
}

void TstBackend::mapProxyFiltersByBoard()
{
    Repository repo;
    const int boardA = repo.boards().first().id;
    const int colA = repo.columnsForBoard(boardA).first().id;
    const int boardB = repo.addBoard(QStringLiteral("Peta B"));
    const int colB = repo.addColumn(boardB, QStringLiteral("Kolom B"));

    const int inA = repo.addItem(QStringLiteral("a"), QString(), QDate::currentDate());
    const int inB = repo.addItem(QStringLiteral("b"), QString(), QDate::currentDate());
    const int inInbox = repo.addItem(QStringLiteral("inbox"), QString(), QDate::currentDate());
    repo.moveItem(inA, colA, 0);
    repo.moveItem(inB, colB, 0);

    ItemModel model(&repo);
    MapProxyModel proxy;
    proxy.setSourceModel(&model);
    QCoreApplication::processEvents();

    auto idsOf = [&]() {
        QList<int> out;
        for (int r = 0; r < proxy.rowCount(); ++r)
            out.append(proxy.index(r, 0).data(ItemModel::IdRole).toInt());
        return out;
    };

    // boardId -1 (Global) → semua Item termasuk yang di Inbox
    proxy.setBoardId(-1);
    QCOMPARE(proxy.rowCount(), 3);
    QSet<int> allIds;
    for (int id : idsOf())
        allIds.insert(id);
    QCOMPARE(allIds, QSet<int>({ inA, inB, inInbox }));

    // Filter per board → hanya Item milik board tsb
    proxy.setBoardId(boardA);
    QCOMPARE(proxy.rowCount(), 1);
    QCOMPARE(proxy.index(0, 0).data(ItemModel::IdRole).toInt(), inA);

    proxy.setBoardId(boardB);
    QCOMPARE(proxy.rowCount(), 1);
    QCOMPARE(proxy.index(0, 0).data(ItemModel::IdRole).toInt(), inB);

    // Board tanpa Item → kosong
    const int boardEmpty = repo.addBoard(QStringLiteral("Kosong"));
    proxy.setBoardId(boardEmpty);
    QCOMPARE(proxy.rowCount(), 0);
}

void TstBackend::edgeCrudRoundtrip()
{
    Repository repo;
    const int a = repo.addItem(QStringLiteral("A"), QString(), QDate::currentDate());
    const int b = repo.addItem(QStringLiteral("B"), QString(), QDate::currentDate());
    const int c = repo.addItem(QStringLiteral("C"), QString(), QDate::currentDate());
    QVERIFY(a > 0 && b > 0 && c > 0);

    QCOMPARE(repo.edges().size(), 0);
    QVERIFY(!repo.edgeExists(a, b));

    // Buat edge A → B (B induk)
    QVERIFY(repo.addEdge(a, b));
    QVERIFY(repo.edgeExists(a, b));
    QCOMPARE(repo.edges().size(), 1);
    QCOMPARE(repo.edges().first().itemId, a);
    QCOMPARE(repo.edges().first().parentItemId, b);
    QCOMPARE(repo.edges().first().kind, QStringLiteral("relasi"));

    // Duplikat & self-loop ditolak
    QVERIFY(!repo.addEdge(a, b));
    QVERIFY(!repo.addEdge(a, a));
    QCOMPARE(repo.edges().size(), 1);

    // edgeList (jembatan QML) berisi map yang benar
    const auto lst = repo.edgeList();
    QCOMPARE(lst.size(), 1);
    const QVariantMap m = lst.first().toMap();
    QCOMPARE(m.value(QStringLiteral("itemId")).toInt(), a);
    QCOMPARE(m.value(QStringLiteral("parentItemId")).toInt(), b);

    // Beberapa edge boleh paralel dari induk yang sama
    QVERIFY(repo.addEdge(c, b));

    // Hapus edge → hilang
    repo.deleteEdge(repo.edges().first().id);
    QCOMPARE(repo.edges().size(), 1);
    QVERIFY(!repo.edgeExists(a, b));
    QVERIFY(repo.edgeExists(c, b));

    // Edge lain tidak terhapus (hapus item induk b → semua edge b hilang via CASCADE)
    repo.deleteItem(b);
    QCOMPARE(repo.edges().size(), 0);
}

void TstBackend::edgePersistsAcrossReopen()
{
    Repository repo;
    const int a = repo.addItem(QStringLiteral("A"), QString(), QDate::currentDate());
    const int b = repo.addItem(QStringLiteral("B"), QString(), QDate::currentDate());
    QVERIFY(repo.addEdge(a, b));

    db::close();
    QString error;
    QVERIFY2(db::open(path, &error), qPrintable(error));
    QVERIFY(db::initSchema());

    Repository repo2;
    const auto es = repo2.edges();
    QCOMPARE(es.size(), 1);
    QCOMPARE(es.first().itemId, a);
    QCOMPARE(es.first().parentItemId, b);
    QVERIFY(repo2.edgeExists(a, b));
}

void TstBackend::shapeCrudRoundtrip()
{
    Repository repo;
    const int boardId = repo.boards().first().id;

    QSignalSpy spy(&repo, &Repository::changed);

    const int shapeId = repo.addShape(boardId, QStringLiteral("rectangle"),
        10.0, 20.0, 100.0, 50.0, 0.0,
        QStringLiteral("[]"),
        QStringLiteral("{\"stroke\":\"border\",\"fill\":\"surface\",\"strokeWidth\":2}"));
    QVERIFY(shapeId > 0);
    QCOMPARE(spy.count(), 1);

    auto list = repo.shapeList(boardId);
    QCOMPARE(list.size(), 1);
    const QVariantMap m = list.first().toMap();
    QCOMPARE(m.value(QStringLiteral("id")).toInt(), shapeId);
    QCOMPARE(m.value(QStringLiteral("boardId")).toInt(), boardId);
    QCOMPARE(m.value(QStringLiteral("type")).toString(), QStringLiteral("rectangle"));
    QCOMPARE(m.value(QStringLiteral("x")).toDouble(), 10.0);
    QCOMPARE(m.value(QStringLiteral("y")).toDouble(), 20.0);
    QCOMPARE(m.value(QStringLiteral("width")).toDouble(), 100.0);
    QCOMPARE(m.value(QStringLiteral("height")).toDouble(), 50.0);
    QCOMPARE(m.value(QStringLiteral("rotation")).toDouble(), 0.0);
    QCOMPARE(m.value(QStringLiteral("linkedItemId")).toInt(), -1);
    // points/style di-parse dari JSON di sisi C++
    QCOMPARE(m.value(QStringLiteral("points")).toList().size(), 0);
    QCOMPARE(m.value(QStringLiteral("style")).toMap()
                 .value(QStringLiteral("stroke")).toString(), QStringLiteral("border"));

    // updateShapePosition memperbarui geometri + rotation
    repo.updateShapePosition(shapeId, 99.5, 88.0, 60.0, 30.0, 45.0);
    QCOMPARE(spy.count(), 2);
    list = repo.shapeList(boardId);
    QCOMPARE(list.size(), 1);
    const QVariantMap moved = list.first().toMap();
    QCOMPARE(moved.value(QStringLiteral("x")).toDouble(), 99.5);
    QCOMPARE(moved.value(QStringLiteral("y")).toDouble(), 88.0);
    QCOMPARE(moved.value(QStringLiteral("width")).toDouble(), 60.0);
    QCOMPARE(moved.value(QStringLiteral("height")).toDouble(), 30.0);
    QCOMPARE(moved.value(QStringLiteral("rotation")).toDouble(), 45.0);

    repo.deleteShape(shapeId);
    QCOMPARE(spy.count(), 3);
    QCOMPARE(repo.shapeList(boardId).size(), 0);
}

void TstBackend::shapeGlobalVsBoardFilter()
{
    Repository repo;
    const int boardA = repo.boards().first().id;
    const int boardB = repo.addBoard(QStringLiteral("Shape Bantu"));

    const int localId = repo.addShape(boardA, QStringLiteral("ellipse"),
        1.0, 2.0, 10.0, 20.0, 0.0, QStringLiteral("[]"),
        QStringLiteral("{\"stroke\":\"accent\"}"));
    const int globalId = repo.addShape(-1, QStringLiteral("line"),
        5.0, 6.0, 30.0, 0.0, 15.0,
        QStringLiteral("[[0,0],[1,1]]"),
        QStringLiteral("{\"stroke\":\"accent\"}"));
    QVERIFY(localId > 0 && globalId > 0);

    // Global (-1) → semua bentuk
    QCOMPARE(repo.shapeList(-1).size(), 2);

    // Per board → hanya bentuk milik board tsb
    auto listA = repo.shapeList(boardA);
    QCOMPARE(listA.size(), 1);
    QCOMPARE(listA.first().toMap().value(QStringLiteral("id")).toInt(), localId);

    QCOMPARE(repo.shapeList(boardB).size(), 0);

    // Bentuk global dilaporkan boardId -1 dan points ter-parse
    bool foundGlobal = false;
    for (const QVariant &v : repo.shapeList(-1)) {
        const QVariantMap m = v.toMap();
        if (m.value(QStringLiteral("id")).toInt() != globalId)
            continue;
        foundGlobal = true;
        QCOMPARE(m.value(QStringLiteral("boardId")).toInt(), -1);
        QCOMPARE(m.value(QStringLiteral("rotation")).toDouble(), 15.0);
        const QVariantList pts = m.value(QStringLiteral("points")).toList();
        QCOMPARE(pts.size(), 2);
        QCOMPARE(pts.at(0).toList().at(0).toDouble(), 0.0);
        QCOMPARE(pts.at(1).toList().at(1).toDouble(), 1.0);
    }
    QVERIFY2(foundGlobal, "bentuk global tidak ada di shapeList(-1)");
}

void TstBackend::shapePersistsAcrossReopen()
{
    Repository repo;
    const int boardId = repo.boards().first().id;
    const int shapeId = repo.addShape(boardId, QStringLiteral("freehand"),
        -30.0, -25.0, 200.0, 150.0, 90.0,
        QStringLiteral("[[0.1,0.2],[0.5,0.8]]"),
        QStringLiteral("{\"stroke\":\"border\"}"));
    QVERIFY(shapeId > 0);

    db::close();
    QString error;
    QVERIFY2(db::open(path, &error), qPrintable(error));
    QVERIFY(db::initSchema());

    Repository repo2;
    const auto list = repo2.shapeList(boardId);
    QCOMPARE(list.size(), 1);
    const QVariantMap m = list.first().toMap();
    QCOMPARE(m.value(QStringLiteral("id")).toInt(), shapeId);
    QCOMPARE(m.value(QStringLiteral("type")).toString(), QStringLiteral("freehand"));
    QCOMPARE(m.value(QStringLiteral("x")).toDouble(), -30.0);
    QCOMPARE(m.value(QStringLiteral("rotation")).toDouble(), 90.0);
    QCOMPARE(m.value(QStringLiteral("points")).toList().size(), 2);
    QCOMPARE(m.value(QStringLiteral("style")).toMap()
                 .value(QStringLiteral("stroke")).toString(), QStringLiteral("border"));
}

void TstBackend::boardDeleteCascadesShapes()
{
    Repository repo;
    const int boardId = repo.boards().first().id;
    const int boardB = repo.addBoard(QStringLiteral("Bentuk Hilang"));

    const int localB = repo.addShape(boardId, QStringLiteral("rectangle"),
        1.0, 1.0, 10.0, 10.0, 0.0,
        QStringLiteral("[]"), QStringLiteral("{\"stroke\":\"border\"}"));
    const int globalB = repo.addShape(-1, QStringLiteral("arrow"),
        2.0, 2.0, 20.0, 20.0, 0.0,
        QStringLiteral("[]"), QStringLiteral("{\"stroke\":\"accent\"}"));
    QVERIFY(localB > 0 && globalB > 0);

    // Hapus board → bentuk miliknya ikut terhapus (CASCADE), bentuk global selamat
    repo.deleteBoard(boardId);
    QCOMPARE(repo.shapeList(boardId).size(), 0);
    bool globalAlive = false;
    for (const QVariant &v : repo.shapeList(-1)) {
        if (v.toMap().value(QStringLiteral("id")).toInt() == globalB)
            globalAlive = true;
    }
    QVERIFY(globalAlive);

    repo.addShape(boardB, QStringLiteral("ellipse"), 3.0, 3.0, 5.0, 5.0, 0.0,
                  QStringLiteral("[]"), QStringLiteral("{\"stroke\":\"border\"}"));
    repo.deleteBoard(boardB);
    QCOMPARE(repo.shapeList(boardB).size(), 0);
}

void TstBackend::convertShapeToEntityRoundtrip()
{
    Repository repo;
    const int boardId = repo.boards().first().id;

    const int shapeId = repo.addShape(boardId, QStringLiteral("rectangle"),
        100.0, 200.0, 50.0, 40.0, 0.0,
        QStringLiteral("[]"),
        QStringLiteral("{\"stroke\":\"border\",\"fill\":\"surface\"}"));
    QVERIFY(shapeId > 0);

    const int itemId = repo.convertShapeToEntity(shapeId, QStringLiteral("Kotak area"));
    QVERIFY(itemId > 0);

    // Item baru: board = board bentuk, kolom kosong (Inbox), due hari ini
    bool itemOk = false;
    for (const ItemData &it : repo.items()) {
        if (it.id != itemId)
            continue;
        itemOk = true;
        QCOMPARE(it.title, QStringLiteral("Kotak area"));
        QCOMPARE(it.boardId, boardId);
        QCOMPARE(it.columnId, -1);
        QCOMPARE(it.dueDate, QDate::currentDate());
    }
    QVERIFY2(itemOk, "item hasil konversi tidak ditemukan");

    // Posisi node = tengah bentuk
    QCOMPARE(repo.nodePosition(itemId), QPointF(125.0, 220.0));

    // Bentuk ter-link (linked_item_id terisi)
    const QVariantMap shape = repo.shapeList(boardId).first().toMap();
    QCOMPARE(shape.value(QStringLiteral("linkedItemId")).toInt(), itemId);

    // Konversi ulang ditolak (bentuk sudah ter-link)
    QCOMPARE(repo.convertShapeToEntity(shapeId, QStringLiteral("dua kali")), -1);
}

void TstBackend::itemDeleteUnlinksShape()
{
    Repository repo;

    // Konversi bentuk global → item masuk Inbox (board NULL / -1)
    const int shapeId = repo.addShape(-1, QStringLiteral("triangle"),
        10.0, 10.0, 60.0, 60.0, 0.0,
        QStringLiteral("[]"),
        QStringLiteral("{\"stroke\":\"border\",\"fill\":\"surface\"}"));
    const int itemId = repo.convertShapeToEntity(shapeId, QStringLiteral("Global"));
    QVERIFY(itemId > 0);

    auto shapeOf = [&repo, &shapeId]() {
        for (const QVariant &v : repo.shapeList(-1)) {
            const QVariantMap m = v.toMap();
            if (m.value(QStringLiteral("id")).toInt() == shapeId)
                return m;
        }
        return QVariantMap();
    };
    QCOMPARE(shapeOf().value(QStringLiteral("linkedItemId")).toInt(), itemId);
    for (const ItemData &it : repo.items())
        if (it.id == itemId)
            QCOMPARE(it.boardId, -1);

    // Hapus Item dari view lain → bentuk kembali anotasi bebas (SET NULL)
    repo.deleteItem(itemId);
    QCOMPARE(shapeOf().value(QStringLiteral("linkedItemId")).toInt(), -1);
    QCOMPARE(repo.shapeList(-1).size(), 1); // bentuk bertahan
}

void TstBackend::dateParserGrammar()
{
    const QDate today = QDate::currentDate();

    struct DayCase {
        const char *input;
        int days;
        const char *time;
        const char *clean;
    };
    const DayCase dayCases[] = {
        { "beli susu", 0, "", "beli susu" },
        { "beli susu besok", 1, "", "beli susu" },
        { "rapat lusa", 2, "", "rapat" },
        { "rapat nanti", 0, "", "rapat" },
        { "beli susu hari ini", 0, "", "beli susu" },
        { "3 hari lagi belajar", 3, "", "belajar" },
        { "2 minggu lagi", 14, "", "" },
        { "3hari", 3, "", "" },
        { "2minggu lagi", 14, "", "" },
        { "besok jam 9", 1, "09:00", "" },
        { "pukul 3 sore ngopi", 0, "15:00", "ngopi" },
        { "jam 21 malam", 0, "21:00", "" },
    };
    for (const DayCase &c : dayCases) {
        const ParseResult r = DateParser::parse(QString::fromUtf8(c.input));
        QCOMPARE(r.dueDate, today.addDays(c.days));
        QCOMPARE(r.dueTime.toString(QStringLiteral("HH:mm")), QString::fromUtf8(c.time));
        QCOMPARE(r.cleanTitle, QString::fromUtf8(c.clean));
    }

    const QDate senin = nextMonday(today);
    const QDate seninLalu = prevMonday(today);

    QCOMPARE(DateParser::parse(QStringLiteral("rapat senin")).dueDate, senin);
    QCOMPARE(DateParser::parse(QStringLiteral("rapat senin depan")).dueDate, senin);
    QCOMPARE(DateParser::parse(QStringLiteral("hari senin")).dueDate, senin);
    QCOMPARE(DateParser::parse(QStringLiteral("rapat senin lalu")).dueDate, seninLalu);
    QCOMPARE(DateParser::parse(QStringLiteral("rapat senin jam 9")).dueDate, senin);
    QCOMPARE(DateParser::parse(QStringLiteral("rapat senin jam 9")).dueTime, QTime(9, 0));
    QCOMPARE(DateParser::parse(QStringLiteral("minggu depan")).dueDate, today.addDays(7));
    QCOMPARE(DateParser::parse(QStringLiteral("minggu lalu")).dueDate, today.addDays(-7));
    QCOMPARE(DateParser::parse(QStringLiteral("bulan depan")).dueDate, today.addMonths(1));
    QCOMPARE(DateParser::parse(QStringLiteral("tahun depan")).dueDate, today.addYears(1));
    QCOMPARE(DateParser::parse(QStringLiteral("1 bulan lagi")).dueDate, today.addMonths(1));

    // English grammar
    const struct EnCase {
        const char *input;
        int days;
        const char *time;
    } enCases[] = {
        { "buy milk tomorrow", 1, "" },
        { "call today", 0, "" },
        { "3 days from now submit", 3, "" },
        { "in 4 days pay", 4, "" },
        { "2 weeks later deploy", 14, "" },
        { "next week review", 7, "" },
        { "last week done", -7, "" },
        { "event at 5 pm", 0, "17:00" },
        { "event at 9 am", 0, "09:00" },
        { "event at 17:30", 0, "17:30" },
        { "event at 21:00", 0, "21:00" },
    };
    for (const EnCase &c : enCases) {
        const ParseResult r = DateParser::parse(QString::fromUtf8(c.input));
        QCOMPARE(r.dueDate, today.addDays(c.days));
        QCOMPARE(r.dueTime.toString(QStringLiteral("HH:mm")), QString::fromUtf8(c.time));
    }

    QCOMPARE(DateParser::parse("meeting next monday").dueDate, senin);
    QCOMPARE(DateParser::parse("meeting last monday").dueDate, seninLalu);
    QCOMPARE(DateParser::parse("meeting on monday").dueDate, senin);
    QCOMPARE(DateParser::parse("meeting tuesday").dueDate, nextTuesday(today));
    QCOMPARE(DateParser::parse("monday 9 am standup").dueDate, senin);
    QCOMPARE(DateParser::parse("monday 9 am standup").dueTime, QTime(9, 0));
}

void TstBackend::nodeLayoutProducesLevelsWithoutOverlap()
{
    Repository repo;
    const QDate today = QDate::currentDate();

    // 3 akar + 2 anak (level 1) + 1 cucu (level 2) — edge global lintas board
    const int r1 = repo.addItem(QStringLiteral("akar 1"), QString(), today);
    const int r2 = repo.addItem(QStringLiteral("akar 2"), QString(), today);
    const int r3 = repo.addItem(QStringLiteral("akar 3"), QString(), today);
    const int c1 = repo.addItem(QStringLiteral("anak 1"), QString(), today);
    const int c2 = repo.addItem(QStringLiteral("anak 2"), QString(), today);
    const int g1 = repo.addItem(QStringLiteral("cucu 1"), QString(), today);
    QVERIFY(repo.addEdge(c1, r1));
    QVERIFY(repo.addEdge(c2, r1));
    QVERIFY(repo.addEdge(g1, c1));

    const auto all = repo.items();
    const auto positioned = NodeLayout::layout(all, repo.edges());
    QCOMPARE(positioned.size(), all.size());

    QHash<int, QPointF> pos;
    for (const auto &p : positioned)
        pos.insert(p.itemId, p.pos);

    QVERIFY(pos.contains(r1) && pos.contains(r2) && pos.contains(r3));
    QVERIFY(pos.contains(c1) && pos.contains(c2) && pos.contains(g1));

    // Akar level 0 di kolom paling kiri; anak (level 1) dan cucu (level 2) semakin ke kanan
    QVERIFY(pos.value(c1).x() > pos.value(r1).x());
    QVERIFY(pos.value(c2).x() > pos.value(r1).x());
    QVERIFY(pos.value(g1).x() > pos.value(c1).x());

    // Tidak ada dua node yang menempati koordinat sama
    QSet<QString> cells;
    for (const auto &p : positioned)
        cells.insert(QStringLiteral("%1|%2").arg(p.pos.x()).arg(p.pos.y()));
    QCOMPARE(cells.size(), positioned.size());
}

void TstBackend::nodeLayoutPersistsPositionsViaRepo()
{
    Repository repo;
    const int boardA = repo.addBoard(QStringLiteral("Layout A"));
    const int colA = repo.addColumn(boardA, QStringLiteral("Kolom A"));
    const int boardB = repo.addBoard(QStringLiteral("Layout B"));
    const int colB = repo.addColumn(boardB, QStringLiteral("Kolom B"));

    const int a1 = repo.addItem(QStringLiteral("A1"), QString(), QDate::currentDate());
    const int a2 = repo.addItem(QStringLiteral("A2"), QString(), QDate::currentDate());
    const int b1 = repo.addItem(QStringLiteral("B1"), QString(), QDate::currentDate());
    repo.moveItem(a1, colA, 0);
    repo.moveItem(a2, colA, 0);
    repo.moveItem(b1, colB, 0);
    QVERIFY(repo.addEdge(a2, a1));

    // Layout global (−1) → semua item dapat posisi
    repo.layoutMap(-1);
    QVERIFY(repo.hasNodePosition(a1));
    QVERIFY(repo.hasNodePosition(a2));
    QVERIFY(repo.hasNodePosition(b1));
    QPointF pa = repo.nodePosition(a1);
    QPointF pb = repo.nodePosition(a2);
    QVERIFY(pb.x() > pa.x()); // anak di kanan induk

    // Layout per-board → hanya item board itu yang disentuh, posisi board lain utuh
    const QPointF beforeB = repo.nodePosition(b1);
    repo.layoutMap(boardA);
    QVERIFY(repo.hasNodePosition(a1));
    QVERIFY(repo.hasNodePosition(a2));
    QCOMPARE(repo.nodePosition(b1), beforeB);

    // Item Inbox (belum dipetakan) ikut di-layout dalam mode global
    const int inboxItem = repo.addItem(QStringLiteral("inbox"), QString(), QDate::currentDate());
    repo.layoutMap(-1);
    QVERIFY(repo.hasNodePosition(inboxItem));
}

void TstBackend::cleanup()
{
    db::close();
}

QTEST_MAIN(TstBackend)
#include "tst_backend.moc"