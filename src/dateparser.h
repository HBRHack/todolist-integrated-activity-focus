#pragma once

#include <QDate>
#include <QTime>
#include <QString>

struct ParseResult {
    QDate dueDate;
    QTime dueTime;
    QString cleanTitle;
};

class DateParser {
public:
    static ParseResult parse(const QString &text);

private:
    struct Token {
        QString word;
        int startPos;
        int endPos;
    };

    static QList<Token> tokenize(const QString &text);
    static QDate extractDate(const QList<Token> &tokens, QDate baseDate, QList<int> &consumed);
    static QTime extractTime(const QString &text, QList<int> &consumed);
    static bool isDayName(const QString &word, int &dayOfWeek);
    static bool isRelativeDay(const QString &word, int &daysAhead);
};
