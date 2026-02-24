WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
BadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
CombinedStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.PostCount,
        us.QuestionCount,
        us.AnswerCount,
        us.AcceptedAnswers,
        us.PopularPosts,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount,
        COALESCE(bc.GoldBadges, 0) AS GoldBadges,
        COALESCE(bc.SilverBadges, 0) AS SilverBadges,
        COALESCE(bc.BronzeBadges, 0) AS BronzeBadges
    FROM 
        UserStats us
    LEFT JOIN 
        BadgeCounts bc ON us.UserId = bc.UserId
)
SELECT 
    c.DisplayName,
    c.Reputation,
    c.PostCount,
    c.QuestionCount,
    c.AnswerCount,
    c.AcceptedAnswers,
    c.PopularPosts,
    c.BadgeCount,
    c.GoldBadges,
    c.SilverBadges,
    c.BronzeBadges
FROM 
    CombinedStats c
WHERE 
    c.Reputation > 1000 
    AND c.PostCount > 10
ORDER BY 
    c.Reputation DESC, 
    c.PostCount DESC
LIMIT 100;
