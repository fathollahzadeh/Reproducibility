WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(b.Id) AS BadgeCount, 
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Users u 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id, u.DisplayName
), UserPostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
), CombinedStats AS (
    SELECT 
        ubc.UserId,
        ubc.DisplayName,
        ubc.BadgeCount,
        ubc.GoldCount,
        ubc.SilverCount,
        ubc.BronzeCount,
        ups.PostCount,
        ups.QuestionCount,
        ups.AnswerCount,
        ups.TotalScore,
        ups.AvgViewCount
    FROM 
        UserBadgeCounts ubc
    JOIN 
        UserPostStats ups ON ubc.UserId = ups.OwnerUserId
)
SELECT 
    DisplayName,
    BadgeCount,
    GoldCount,
    SilverCount,
    BronzeCount,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalScore,
    AvgViewCount
FROM 
    CombinedStats
WHERE 
    BadgeCount > 0 
ORDER BY 
    TotalScore DESC, BadgeCount DESC
LIMIT 10;
