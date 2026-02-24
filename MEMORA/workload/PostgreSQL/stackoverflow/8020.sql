WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Users u
        LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    ub.UserId,
    ub.DisplayName,
    ub.BadgeCount,
    ub.GoldCount,
    ub.SilverCount,
    ub.BronzeCount,
    COALESCE(ps.PostCount, 0) AS PostCount,
    COALESCE(ps.QuestionCount, 0) AS QuestionCount,
    COALESCE(ps.AnswerCount, 0) AS AnswerCount,
    COALESCE(ps.TotalScore, 0) AS TotalScore,
    COALESCE(ps.TotalViews, 0) AS TotalViews
FROM 
    UserBadges ub
    LEFT JOIN PostStatistics ps ON ub.UserId = ps.OwnerUserId
ORDER BY 
    ub.BadgeCount DESC, 
    TotalScore DESC
LIMIT 50;