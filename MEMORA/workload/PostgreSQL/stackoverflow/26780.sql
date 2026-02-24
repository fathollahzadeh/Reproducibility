WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
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
ActiveUserPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
CombinedStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        ap.PostCount,
        ap.QuestionCount,
        ap.AnswerCount,
        ap.TotalScore
    FROM 
        Users u
    LEFT JOIN 
        UserBadgeCounts ub ON u.Id = ub.UserId
    LEFT JOIN 
        ActiveUserPosts ap ON u.Id = ap.OwnerUserId
    WHERE 
        u.Reputation > 100
)
SELECT 
    c.UserId,
    c.DisplayName,
    c.Reputation,
    c.BadgeCount,
    c.GoldBadges,
    c.SilverBadges,
    c.BronzeBadges,
    c.PostCount,
    c.QuestionCount,
    c.AnswerCount,
    c.TotalScore,
    CASE 
        WHEN c.TotalScore > 100 THEN 'High Scorer'
        WHEN c.TotalScore BETWEEN 50 AND 100 THEN 'Moderate Scorer'
        ELSE 'Low Scorer'
    END AS ScoringCategory
FROM 
    CombinedStats c
ORDER BY 
    c.TotalScore DESC
LIMIT 100;