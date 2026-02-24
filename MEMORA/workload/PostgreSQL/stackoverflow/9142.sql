WITH UserBadges AS (
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
PostStats AS (
    SELECT 
        p.OwnerUserId,
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
CombinedStats AS (
    SELECT 
        ub.UserId,
        ub.TotalBadges,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        ps.TotalPosts,
        ps.Questions,
        ps.Answers,
        ps.TotalViews,
        ps.TotalScore
    FROM 
        UserBadges ub
    LEFT JOIN 
        PostStats ps ON ub.UserId = ps.OwnerUserId
)
SELECT 
    u.DisplayName, 
    cs.TotalBadges,
    cs.GoldBadges, 
    cs.SilverBadges,
    cs.BronzeBadges,
    cs.TotalPosts, 
    cs.Questions, 
    cs.Answers, 
    cs.TotalViews, 
    cs.TotalScore
FROM 
    CombinedStats cs
JOIN 
    Users u ON cs.UserId = u.Id
WHERE 
    cs.TotalPosts > 5
ORDER BY 
    cs.TotalScore DESC, 
    cs.TotalBadges DESC
LIMIT 10;