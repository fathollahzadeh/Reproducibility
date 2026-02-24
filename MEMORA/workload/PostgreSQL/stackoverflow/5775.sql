
WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges,
        SUM(CASE WHEN b.Class IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
), PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS Answers,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year' 
    GROUP BY 
        p.OwnerUserId
), CombinedStats AS (
    SELECT 
        ubs.UserId,
        ubs.DisplayName,
        ubs.GoldBadges,
        ubs.SilverBadges,
        ubs.BronzeBadges,
        ubs.TotalBadges,
        ps.TotalPosts,
        ps.Questions,
        ps.Answers,
        ps.AverageScore,
        ps.TotalViews
    FROM 
        UserBadgeStats ubs
    LEFT JOIN 
        PostStats ps ON ubs.UserId = ps.OwnerUserId
)
SELECT 
    cs.DisplayName,
    cs.TotalBadges,
    cs.GoldBadges,
    cs.SilverBadges,
    cs.BronzeBadges,
    cs.TotalPosts,
    cs.Questions,
    cs.Answers,
    cs.AverageScore,
    cs.TotalViews
FROM 
    CombinedStats cs
ORDER BY 
    cs.TotalBadges DESC, cs.TotalPosts DESC
LIMIT 10;
