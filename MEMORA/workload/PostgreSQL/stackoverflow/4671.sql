
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
CombinedStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.Views,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.Questions, 0) AS Questions,
        COALESCE(ps.Answers, 0) AS Answers,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        us.BadgeCount,
        ps.AverageScore
    FROM 
        UserStats us
    LEFT JOIN 
        PostStats ps ON us.UserId = ps.OwnerUserId
)
SELECT 
    cs.DisplayName,
    cs.Reputation,
    cs.Views,
    cs.TotalPosts,
    cs.Questions,
    cs.Answers,
    cs.BadgeCount,
    cs.GoldBadges,
    cs.SilverBadges,
    cs.BronzeBadges,
    CASE 
        WHEN cs.AverageScore IS NULL THEN 'No Posts' 
        ELSE CAST(cs.AverageScore AS VARCHAR) 
    END AS AveragePostScore
FROM 
    CombinedStats cs
WHERE 
    cs.Reputation > (SELECT AVG(Reputation) FROM Users) 
ORDER BY 
    cs.Reputation DESC
LIMIT 10;
