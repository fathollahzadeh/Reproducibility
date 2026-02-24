WITH UserScoreStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score >= 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopContributors AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        PositivePosts, 
        NegativePosts, 
        PopularPosts, 
        AverageScore,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserScoreStats
),
BadgeStats AS (
    SELECT 
        userId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        userId
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.Reputation,
    t.PostCount,
    t.PositivePosts,
    t.NegativePosts,
    t.PopularPosts,
    t.AverageScore,
    b.BadgeCount,
    b.GoldBadges,
    b.SilverBadges,
    b.BronzeBadges
FROM 
    TopContributors t
LEFT JOIN 
    BadgeStats b ON t.UserId = b.userId
WHERE 
    t.ReputationRank <= 10
ORDER BY 
    t.Reputation DESC;
