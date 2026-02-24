WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
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
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.Questions, 0) AS Questions,
        COALESCE(ps.Answers, 0) AS Answers,
        COALESCE(ps.AvgScore, 0) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    ua.TotalPosts,
    ua.Questions,
    ua.Answers,
    ua.AvgScore,
    RANK() OVER (ORDER BY ua.Reputation DESC) AS ReputationRank
FROM 
    UserActivity ua
WHERE 
    ua.Reputation > 1000 AND 
    (ua.GoldBadges + ua.SilverBadges + ua.BronzeBadges > 0 OR ua.TotalPosts > 10)
ORDER BY 
    ua.Reputation DESC
LIMIT 50;
