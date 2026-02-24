WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(c.Id, 0)) AS CommentCount
    FROM 
        Users AS u
    LEFT JOIN 
        Posts AS p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments AS c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        ba.UserId,
        COUNT(ba.Id) AS BadgeCount
    FROM 
        Badges AS ba
    GROUP BY 
        ba.UserId
),
TotalStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.PostCount,
        ups.QuestionCount,
        ups.AnswerCount,
        ups.TotalScore,
        ups.TotalViews,
        ups.CommentCount,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount
    FROM 
        UserPostStats AS ups
    LEFT JOIN 
        UserBadges AS ub ON ups.UserId = ub.UserId
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalScore,
    TotalViews,
    CommentCount,
    BadgeCount
FROM 
    TotalStats
ORDER BY 
    TotalScore DESC
LIMIT 100;