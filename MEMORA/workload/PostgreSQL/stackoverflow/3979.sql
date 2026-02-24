
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        PopularPosts, 
        AverageScore,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserPostStats
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ubs.TotalBadges, 0) AS TotalBadges,
        COALESCE(ubs.GoldBadges, 0) AS GoldBadges,
        ups.TotalPosts,
        ups.PopularPosts,
        ups.AverageScore,
        RANK() OVER (ORDER BY ups.TotalPosts DESC) AS PostRank
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ubs ON u.Id = ubs.UserId
    LEFT JOIN 
        UserPostStats ups ON u.Id = ups.UserId
),
PopularUserActivity AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalBadges,
        GoldBadges,
        TotalPosts,
        PopularPosts,
        AverageScore,
        PostRank
    FROM 
        UserActivity
    WHERE 
        TotalPosts > 0
),
FinalResults AS (
    SELECT 
        pu.UserId,
        pu.DisplayName,
        pu.TotalBadges,
        pu.GoldBadges,
        pu.TotalPosts,
        pu.PopularPosts,
        pu.AverageScore,
        pu.PostRank,
        CASE 
            WHEN pu.AverageScore > 50 THEN 'High Engagement'
            WHEN pu.AverageScore BETWEEN 20 AND 50 THEN 'Moderate Engagement'
            ELSE 'Low Engagement'
        END AS EngagementLevel
    FROM 
        PopularUserActivity pu
    WHERE 
        pu.PostRank <= 10
)
SELECT 
    fr.DisplayName,
    fr.TotalBadges,
    fr.GoldBadges,
    fr.TotalPosts,
    fr.PopularPosts,
    fr.AverageScore,
    fr.EngagementLevel,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypeNames
FROM 
    FinalResults fr
LEFT JOIN 
    Posts p ON p.OwnerUserId = fr.UserId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    fr.UserId, fr.DisplayName, fr.TotalBadges, fr.GoldBadges,
    fr.TotalPosts, fr.PopularPosts, fr.AverageScore, fr.EngagementLevel, 
    fr.PostRank
ORDER BY 
    fr.PostRank;
