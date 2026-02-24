
WITH UserBadgeCounts AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(Badges.Id) AS BadgeCount
    FROM 
        Users
    LEFT JOIN 
        Badges ON Users.Id = Badges.UserId
    GROUP BY 
        Users.Id, Users.DisplayName
),
PostStats AS (
    SELECT 
        Posts.OwnerUserId,
        COUNT(Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(Posts.ViewCount) AS TotalViews,
        AVG(Posts.Score) AS AverageScore
    FROM 
        Posts
    GROUP BY 
        Posts.OwnerUserId
),
CombinedStats AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        u.LastAccessDate,
        COALESCE(pc.PostCount, 0) AS PostCount,
        COALESCE(pc.QuestionCount, 0) AS QuestionCount,
        COALESCE(pc.AnswerCount, 0) AS AnswerCount,
        COALESCE(pc.TotalViews, 0) AS TotalViews,
        COALESCE(pc.AverageScore, 0) AS AverageScore,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        PostStats pc ON u.Id = pc.OwnerUserId
    LEFT JOIN 
        UserBadgeCounts bc ON u.Id = bc.UserId
)
SELECT 
    DisplayName,
    Reputation,
    LastAccessDate,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalViews,
    AverageScore,
    BadgeCount
FROM 
    CombinedStats
WHERE 
    BadgeCount > 0
ORDER BY 
    TotalViews DESC, Reputation DESC
LIMIT 10;
