
WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
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
ActiveUsersPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers
    FROM 
        Posts p
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ubs.TotalBadges, 0) AS TotalBadges,
        COALESCE(aup.TotalPosts, 0) AS TotalPosts,
        COALESCE(aup.Questions, 0) AS Questions,
        COALESCE(aup.Answers, 0) AS Answers,
        u.Reputation
    FROM 
        Users u
    LEFT JOIN 
        UserBadgeStats ubs ON u.Id = ubs.UserId
    LEFT JOIN 
        ActiveUsersPosts aup ON u.Id = aup.OwnerUserId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.TotalBadges,
    up.TotalPosts,
    up.Questions,
    up.Answers,
    up.Reputation,
    RANK() OVER (ORDER BY up.Reputation DESC) AS ReputationRank,
    RANK() OVER (ORDER BY up.TotalPosts DESC) AS PostRank
FROM 
    UserPerformance up
WHERE 
    up.TotalPosts > 0
ORDER BY 
    up.Reputation DESC, 
    up.TotalPosts DESC
LIMIT 10;
