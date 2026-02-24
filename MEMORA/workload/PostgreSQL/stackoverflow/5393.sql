WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViewCount,
        COUNT(DISTINCT p.Tags) AS UniqueTags
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
CombinedStats AS (
    SELECT 
        u.UserId,
        u.Reputation,
        u.BadgeCount,
        u.GoldBadges,
        u.SilverBadges,
        u.BronzeBadges,
        p.PostCount,
        p.TotalScore,
        p.AverageViewCount,
        p.UniqueTags
    FROM 
        UserReputation u
    LEFT JOIN 
        PostStats p ON u.UserId = p.OwnerUserId
)
SELECT 
    cs.UserId,
    cs.Reputation,
    cs.BadgeCount,
    cs.GoldBadges,
    cs.SilverBadges,
    cs.BronzeBadges,
    COALESCE(cs.PostCount, 0) AS PostCount,
    COALESCE(cs.TotalScore, 0) AS TotalScore,
    COALESCE(cs.AverageViewCount, 0) AS AverageViewCount,
    COALESCE(cs.UniqueTags, 0) AS UniqueTags
FROM 
    CombinedStats cs
ORDER BY 
    cs.Reputation DESC, cs.TotalScore DESC;
