WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBountyAmount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM Posts p
    GROUP BY p.OwnerUserId
),
CombinedStats AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(up.PostCount, 0) AS PostCount,
        COALESCE(up.QuestionCount, 0) AS QuestionCount,
        COALESCE(up.AnswerCount, 0) AS AnswerCount,
        COALESCE(up.TotalScore, 0) AS TotalScore,
        COALESCE(up.AvgViewCount, 0) AS AvgViewCount,
        u.BadgeCount,
        u.TotalBountyAmount
    FROM UserStats u
    LEFT JOIN PostStats up ON u.UserId = up.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalScore,
    AvgViewCount,
    BadgeCount,
    TotalBountyAmount
FROM CombinedStats
ORDER BY Reputation DESC, TotalScore DESC;