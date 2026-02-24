WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostCounts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS Answers
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(b.GoldBadges, 0) AS GoldBadges,
        COALESCE(b.SilverBadges, 0) AS SilverBadges,
        COALESCE(b.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(pc.TotalPosts, 0) AS TotalPosts,
        COALESCE(pc.Questions, 0) AS Questions,
        COALESCE(pc.Answers, 0) AS Answers,
        r.ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        UserBadges b ON u.Id = b.UserId
    LEFT JOIN 
        PostCounts pc ON u.Id = pc.OwnerUserId
    JOIN 
        RankedUsers r ON u.Id = r.UserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.ReputationRank,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    us.TotalPosts,
    us.Questions,
    us.Answers,
    CASE 
        WHEN us.ReputationRank <= 10 THEN 'Top User'
        WHEN us.ReputationRank BETWEEN 11 AND 50 THEN 'Popular User'
        ELSE 'New User'
    END AS UserCategory
FROM 
    UserStats us
WHERE 
    us.TotalPosts > 0
ORDER BY 
    us.ReputationRank ASC
LIMIT 50;