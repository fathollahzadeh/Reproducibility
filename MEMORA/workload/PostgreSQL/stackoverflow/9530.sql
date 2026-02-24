
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
BadgeSummary AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostScoreSummary AS (
    SELECT 
        p.OwnerUserId,
        SUM(p.Score) AS TotalScore,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.PostCount,
    ur.AnswerCount,
    COALESCE(bs.GoldBadges, 0) AS GoldBadges,
    COALESCE(bs.SilverBadges, 0) AS SilverBadges,
    COALESCE(bs.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(pss.TotalScore, 0) AS TotalScore,
    COALESCE(pss.AverageScore, 0) AS AverageScore
FROM 
    UserReputation ur
LEFT JOIN 
    BadgeSummary bs ON ur.UserId = bs.UserId
LEFT JOIN 
    PostScoreSummary pss ON ur.UserId = pss.OwnerUserId
ORDER BY 
    ur.Reputation DESC, ur.PostCount DESC, ur.AnswerCount DESC;
