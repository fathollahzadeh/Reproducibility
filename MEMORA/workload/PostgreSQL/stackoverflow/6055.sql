WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
UserPostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS ScorePositive,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
CombinedStats AS (
    SELECT 
        ubc.UserId,
        ubc.DisplayName,
        ubc.BadgeCount,
        ubc.GoldBadges,
        ubc.SilverBadges,
        ubc.BronzeBadges,
        ups.PostCount,
        ups.ScorePositive,
        ups.Questions,
        ups.Answers
    FROM 
        UserBadgeCounts ubc
    LEFT JOIN 
        UserPostStats ups ON ubc.UserId = ups.OwnerUserId
)
SELECT 
    *
FROM 
    CombinedStats
ORDER BY 
    BadgeCount DESC,
    ScorePositive DESC,
    PostCount DESC
LIMIT 100;