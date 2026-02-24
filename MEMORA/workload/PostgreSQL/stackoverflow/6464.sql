WITH PostCounts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 4 THEN 1 ELSE 0 END) AS TotalTagWikis
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
), UserReputations AS (
    SELECT 
        u.Id,
        u.Reputation,
        COALESCE(pc.TotalPosts, 0) AS TotalPosts,
        COALESCE(pc.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(pc.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(pc.TotalTagWikis, 0) AS TotalTagWikis
    FROM 
        Users u
    LEFT JOIN 
        PostCounts pc ON u.Id = pc.OwnerUserId
), BadgesSummary AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    ur.Id AS UserId,
    ur.Reputation,
    ur.TotalPosts,
    ur.TotalQuestions,
    ur.TotalAnswers,
    ur.TotalTagWikis,
    COALESCE(bs.TotalBadges, 0) AS TotalBadges,
    COALESCE(bs.GoldBadges, 0) AS GoldBadges,
    COALESCE(bs.SilverBadges, 0) AS SilverBadges,
    COALESCE(bs.BronzeBadges, 0) AS BronzeBadges,
    (ur.Reputation / NULLIF(ur.TotalPosts, 0)) AS ReputationPerPost
FROM 
    UserReputations ur
LEFT JOIN 
    BadgesSummary bs ON ur.Id = bs.UserId
ORDER BY 
    ur.Reputation DESC, 
    ur.TotalPosts DESC
LIMIT 100;