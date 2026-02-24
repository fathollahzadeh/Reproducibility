WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
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
PostActivity AS (
    SELECT 
        p.OwnerUserId AS UserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
UserPerformanceStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(ubs.TotalBadges, 0) AS TotalBadges,
        COALESCE(pas.TotalPosts, 0) AS TotalPosts,
        COALESCE(pas.Questions, 0) AS Questions,
        COALESCE(pas.Answers, 0) AS Answers,
        COALESCE(pas.TotalViews, 0) AS TotalViews,
        COALESCE(pas.TotalScore, 0) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        UserBadgeStats ubs ON u.Id = ubs.UserId
    LEFT JOIN 
        PostActivity pas ON u.Id = pas.UserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.Reputation,
    ups.TotalBadges,
    ups.TotalPosts,
    ups.Questions,
    ups.Answers,
    ups.TotalViews,
    ups.TotalScore
FROM 
    UserPerformanceStats ups
ORDER BY 
    ups.Reputation DESC, 
    ups.TotalScore DESC
LIMIT 10;