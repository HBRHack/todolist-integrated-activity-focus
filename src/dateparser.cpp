#include "dateparser.h"

#include <QRegularExpression>
#include <QTime>
#include <QDate>
#include <QMap>
#include <QRegularExpressionMatchIterator>

QList<DateParser::Token> DateParser::tokenize(const QString &text)
{
    QList<Token> tokens;
    QRegularExpression wordRe(QStringLiteral("\\S+"));
    QRegularExpressionMatchIterator it = wordRe.globalMatch(text);
    while (it.hasNext()) {
        QRegularExpressionMatch m = it.next();
        tokens.append({m.captured().toLower(), m.capturedStart(), m.capturedEnd()});
    }
    return tokens;
}

bool DateParser::isDayName(const QString &word, int &dayOfWeek)
{
    static const QMap<QString, int> days = {
        {QStringLiteral("senin"), 1}, {QStringLiteral("selasa"), 2},
        {QStringLiteral("rabu"), 3}, {QStringLiteral("kamis"), 4},
        {QStringLiteral("jumat"), 5}, {QStringLiteral("sabtu"), 6},
        {QStringLiteral("minggu"), 0}
    };
    auto it = days.find(word);
    if (it == days.end())
        return false;
    dayOfWeek = it.value();
    return true;
}

bool DateParser::isRelativeDay(const QString &word, int &daysAhead)
{
    static const QMap<QString, int> relDays = {
        {QStringLiteral("besok"), 1}, {QStringLiteral("lusa"), 2}
    };
    auto it = relDays.find(word);
    if (it == relDays.end())
        return false;
    daysAhead = it.value();
    return true;
}

QTime DateParser::extractTime(const QString &text, QList<int> &consumed)
{
    static const QRegularExpression timeRe(
        QStringLiteral("(?:jam|pukul)\\s+(\\d{1,2})(?::(\\d{2}))?\\s*(pagi|siang|sore|malam)?"),
        QRegularExpression::CaseInsensitiveOption);
    QRegularExpressionMatch m = timeRe.match(text);
    if (!m.hasMatch())
        return QTime();

    int hour = m.captured(1).toInt();
    int minute = m.captured(2).isEmpty() ? 0 : m.captured(2).toInt();
    QString period = m.captured(3).toLower();

    if (period == QStringLiteral("sore") || period == QStringLiteral("malam")) {
        if (hour < 12)
            hour += 12;
    } else if (period.isEmpty() && hour >= 1 && hour <= 6) {
        hour += 12;
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59)
        return QTime();

    consumed.append(m.capturedStart());
    consumed.append(m.capturedEnd());
    return QTime(hour, minute);
}

QDate DateParser::extractDate(const QList<Token> &tokens, QDate baseDate, QList<int> &consumed)
{
    struct Unit {
        enum Type {
            Today, Nanti, DayName, DayNameDepan, DayNameLalu,
            Relative, NumberUnit, UnitDepan, UnitLalu
        };
        Type type = Today;
        int start = 0;
        int end = 0;
        int dayOfWeek = -1;
        int amount = 0;
        QString unit;
    };

    const int n = tokens.size();
    QList<Unit> units;
    int i = 0;
    while (i < n) {
        const Token &tok = tokens.at(i);
        if (consumed.contains(tok.startPos)) {
            ++i;
            continue;
        }

        const Token *nx = (i + 1 < n && !consumed.contains(tokens.at(i + 1).startPos))
            ? &tokens.at(i + 1) : nullptr;
        const Token *nn = (i + 2 < n && !consumed.contains(tokens.at(i + 2).startPos))
            ? &tokens.at(i + 2) : nullptr;

        auto isNumber = [](const QString &w) {
            if (w.isEmpty())
                return false;
            for (const QChar &c : w) {
                if (!c.isDigit())
                    return false;
            }
            return true;
        };
        auto isUnitWord = [](const QString &w) {
            return w == QStringLiteral("hari") || w == QStringLiteral("minggu")
                || w == QStringLiteral("bulan") || w == QStringLiteral("tahun");
        };

        Unit u;
        u.start = tok.startPos;
        u.end = tok.endPos;
        bool matched = true;
        int step = 1;

        if (tok.word == QStringLiteral("nanti")) {
            u.type = Unit::Nanti;
        } else if (tok.word == QStringLiteral("hari")) {
            if (nx && nx->word == QStringLiteral("ini")) {
                u.type = Unit::Today;
                u.end = nx->endPos;
                step = 2;
            } else if (nx && isDayName(nx->word, u.dayOfWeek)) {
                u.type = Unit::DayName;
                u.end = nx->endPos;
                step = 2;
                if (nn && nn->word == QStringLiteral("depan")) {
                    u.type = Unit::DayNameDepan;
                    u.end = nn->endPos;
                    step = 3;
                } else if (nn && nn->word == QStringLiteral("lalu")) {
                    u.type = Unit::DayNameLalu;
                    u.end = nn->endPos;
                    step = 3;
                }
            } else {
                u.type = Unit::Today;
            }
        } else if (isRelativeDay(tok.word, u.amount)) {
            u.type = Unit::Relative;
        } else if (tok.word == QStringLiteral("minggu")
                   || tok.word == QStringLiteral("bulan")
                   || tok.word == QStringLiteral("tahun")) {
            if (nx && nx->word == QStringLiteral("depan")) {
                u.type = Unit::UnitDepan;
                u.unit = tok.word;
                u.end = nx->endPos;
                step = 2;
            } else if (nx && nx->word == QStringLiteral("lalu")) {
                u.type = Unit::UnitLalu;
                u.unit = tok.word;
                u.end = nx->endPos;
                step = 2;
            } else if (isDayName(tok.word, u.dayOfWeek)) {
                u.type = Unit::DayName;
            } else {
                matched = false;
            }
        } else if (isDayName(tok.word, u.dayOfWeek)) {
            u.type = Unit::DayName;
            if (nx && nx->word == QStringLiteral("depan")) {
                u.type = Unit::DayNameDepan;
                u.end = nx->endPos;
                step = 2;
            } else if (nx && nx->word == QStringLiteral("lalu")) {
                u.type = Unit::DayNameLalu;
                u.end = nx->endPos;
                step = 2;
            }
        } else if (isNumber(tok.word) && nx && isUnitWord(nx->word)) {
            u.type = Unit::NumberUnit;
            u.amount = tok.word.toInt();
            u.unit = nx->word;
            u.end = nx->endPos;
            step = 2;
            if (nn && nn->word == QStringLiteral("lagi")) {
                u.end = nn->endPos;
                step = 3;
            }
        } else if (isNumber(tok.word) && nx && nx->word == QStringLiteral("lagi")
                   && i + 2 < n && isUnitWord(tokens.at(i + 2).word)
                   && !consumed.contains(tokens.at(i + 2).startPos)) {
            u.type = Unit::NumberUnit;
            u.amount = tok.word.toInt();
            u.unit = tokens.at(i + 2).word;
            u.end = tokens.at(i + 2).endPos;
            step = 3;
        } else {
            static const QRegularExpression gluedRe(
                QStringLiteral("^(\\d+)(hari|minggu|bulan|tahun)$"));
            QRegularExpressionMatch gm = gluedRe.match(tok.word);
            if (gm.hasMatch()) {
                u.type = Unit::NumberUnit;
                u.amount = gm.captured(1).toInt();
                u.unit = gm.captured(2);
                if (nx && nx->word == QStringLiteral("lagi")) {
                    u.end = nx->endPos;
                    step = 2;
                }
            } else {
                matched = false;
            }
        }

        if (matched)
            units.append(u);
        i += step;
    }

    for (const Unit &u : units) {
        QDate result;
        switch (u.type) {
        case Unit::Today:
        case Unit::Nanti:
            result = baseDate;
            break;
        case Unit::Relative:
            result = baseDate.addDays(u.amount);
            break;
        case Unit::DayName:
        case Unit::DayNameDepan: {
            int diff = (u.dayOfWeek - baseDate.dayOfWeek() + 7) % 7;
            if (diff == 0)
                diff = 7;
            result = baseDate.addDays(diff);
            break;
        }
        case Unit::DayNameLalu: {
            int diff = (baseDate.dayOfWeek() - u.dayOfWeek + 7) % 7;
            if (diff == 0)
                diff = 7;
            result = baseDate.addDays(-diff);
            break;
        }
        case Unit::NumberUnit:
            if (u.unit == QStringLiteral("hari")) {
                result = baseDate.addDays(u.amount);
            } else if (u.unit == QStringLiteral("minggu")) {
                result = baseDate.addDays(u.amount * 7);
            } else if (u.unit == QStringLiteral("bulan")) {
                result = baseDate.addMonths(u.amount);
            } else if (u.unit == QStringLiteral("tahun")) {
                result = baseDate.addYears(u.amount);
            }
            break;
        case Unit::UnitDepan:
            if (u.unit == QStringLiteral("minggu")) {
                result = baseDate.addDays(7);
            } else if (u.unit == QStringLiteral("bulan")) {
                result = baseDate.addMonths(1);
            } else if (u.unit == QStringLiteral("tahun")) {
                result = baseDate.addYears(1);
            }
            break;
        case Unit::UnitLalu:
            if (u.unit == QStringLiteral("minggu")) {
                result = baseDate.addDays(-7);
            } else if (u.unit == QStringLiteral("bulan")) {
                result = baseDate.addMonths(-1);
            } else if (u.unit == QStringLiteral("tahun")) {
                result = baseDate.addYears(-1);
            }
            break;
        }
        if (result.isValid()) {
            consumed.append(u.start);
            consumed.append(u.end);
            return result;
        }
    }
    return QDate();
}

ParseResult DateParser::parse(const QString &text)
{
    ParseResult result;
    result.dueDate = QDate::currentDate();
    result.dueTime = QTime();
    result.cleanTitle = text.trimmed();

    QList<int> consumed;
    QTime time = extractTime(text, consumed);
    if (time.isValid())
        result.dueTime = time;

    QList<Token> tokens = tokenize(text);
    QDate date = extractDate(tokens, QDate::currentDate(), consumed);

    if (date.isValid())
        result.dueDate = date;

    QList<int> cleanRanges;
    for (const Token &tok : tokens) {
        bool isConsumed = false;
        for (int j = 0; j + 1 < consumed.size(); j += 2) {
            const int spanStart = consumed.at(j);
            const int spanEnd = consumed.at(j + 1);
            if (tok.startPos < spanEnd && tok.endPos > spanStart) {
                isConsumed = true;
                break;
            }
        }
        if (!isConsumed)
            cleanRanges.append(tok.startPos);
    }

    QString clean;
    for (int pos : cleanRanges) {
        for (const Token &tok : tokens) {
            if (tok.startPos == pos) {
                if (!clean.isEmpty())
                    clean += QStringLiteral(" ");
                clean += text.mid(tok.startPos, tok.endPos - tok.startPos);
            }
        }
    }
    result.cleanTitle = clean.trimmed();

    return result;
}
