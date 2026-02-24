
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
), MostActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        AnswerCount,
        QuestionCount,
        AcceptedAnswers,
        RANK() OVER (ORDER BY PostCount DESC) AS RankByPosts
    FROM UserStats
    WHERE PostCount > 0
), BadgeSummary AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
), CombinedStats AS (
    SELECT 
        mau.UserId,
        mau.DisplayName,
        mau.Reputation,
        mau.PostCount,
        mau.AnswerCount,
        mau.QuestionCount,
        mau.AcceptedAnswers,
        COALESCE(bs.BadgeCount, 0) AS BadgeCount,
        mau.RankByPosts
    FROM MostActiveUsers mau
    LEFT JOIN BadgeSummary bs ON mau.UserId = bs.UserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    AnswerCount,
    QuestionCount,
    AcceptedAnswers,
    BadgeCount,
    RankByPosts
FROM CombinedStats
WHERE RankByPosts <= 10
ORDER BY Reputation DESC, PostCount DESC;
