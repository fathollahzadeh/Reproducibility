WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Location,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 1) AS QuestionCount,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 2) AS AnswerCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        ur.DisplayName,
        ur.Reputation,
        ur.Location,
        ur.BadgeCount,
        ps.PostCount,
        ps.TotalViews,
        ps.AverageScore,
        ps.QuestionCount,
        ps.AnswerCount
    FROM 
        UserReputation ur
    LEFT JOIN 
        PostStats ps ON ur.UserId = ps.OwnerUserId
)
SELECT 
    up.DisplayName,
    up.Reputation,
    COALESCE(up.Location, 'Unknown') AS Location,
    COALESCE(up.BadgeCount, 0) AS BadgeCount,
    COALESCE(up.PostCount, 0) AS PostCount,
    COALESCE(up.TotalViews, 0) AS TotalViews,
    COALESCE(up.AverageScore, 0) AS AverageScore,
    COALESCE(up.QuestionCount, 0) AS QuestionCount,
    COALESCE(up.AnswerCount, 0) AS AnswerCount
FROM 
    UserPerformance up
ORDER BY 
    up.Reputation DESC,
    up.PostCount DESC
LIMIT 50;