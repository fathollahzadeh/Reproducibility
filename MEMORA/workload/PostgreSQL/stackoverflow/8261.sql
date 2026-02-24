
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
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
        u.Id, u.DisplayName, u.Reputation
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserEngagement AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ps.TotalPosts,
        ps.Questions,
        ps.Answers,
        ps.TotalViews,
        ps.AverageScore,
        ur.BadgeCount,
        ur.GoldBadges,
        ur.SilverBadges,
        ur.BronzeBadges
    FROM 
        UserReputation ur
    JOIN 
        PostStatistics ps ON ur.UserId = ps.OwnerUserId
)
SELECT 
    ue.DisplayName,
    ue.Reputation,
    ue.BadgeCount,
    ue.GoldBadges,
    ue.SilverBadges,
    ue.BronzeBadges,
    ue.TotalPosts,
    ue.Questions,
    ue.Answers,
    ue.TotalViews,
    ue.AverageScore
FROM 
    UserEngagement ue
WHERE 
    ue.Reputation > 1000
ORDER BY 
    ue.Reputation DESC, ue.TotalPosts DESC
LIMIT 10;
