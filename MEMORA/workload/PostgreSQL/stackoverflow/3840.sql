WITH UserBadgeCount AS (
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
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(p.Score) AS AverageScore,
        COUNT(DISTINCT p.Tags) AS UniqueTagsCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.Questions, 0) AS Questions,
        COALESCE(ps.Answers, 0) AS Answers,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        (COALESCE(ps.TotalPosts, 0) + ub.BadgeCount) AS PerformanceScore
    FROM 
        UserBadgeCount ub
    LEFT JOIN 
        PostStatistics ps ON ub.UserId = ps.OwnerUserId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.TotalPosts,
    up.Questions,
    up.Answers,
    up.BadgeCount,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    up.PerformanceScore,
    ROW_NUMBER() OVER (ORDER BY up.PerformanceScore DESC) AS Ranking
FROM 
    UserPerformance up
WHERE 
    up.PerformanceScore > 0
ORDER BY 
    up.PerformanceScore DESC;