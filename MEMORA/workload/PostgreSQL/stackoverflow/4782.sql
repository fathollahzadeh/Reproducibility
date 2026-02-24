
WITH User_Reputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
    WHERE u.Reputation > 1000 
),
Post_Aggregates AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.Score) AS AverageScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
Badges_Analysis AS (
    SELECT 
        b.UserId, 
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
Combined_Analysis AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        pa.TotalPosts,
        pa.TotalQuestions,
        pa.TotalAnswers,
        ba.GoldBadges,
        ba.SilverBadges,
        ba.BronzeBadges,
        ur.ReputationRank
    FROM User_Reputation ur
    LEFT JOIN Post_Aggregates pa ON ur.UserId = pa.OwnerUserId
    LEFT JOIN Badges_Analysis ba ON ur.UserId = ba.UserId
),
User_Metrics AS (
    SELECT 
        ca.*,
        COALESCE(ca.TotalPosts, 0) * 1.0 / NULLIF(ca.ReputationRank, 0) AS PostsPerReputationRank,
        (COALESCE(ca.GoldBadges, 0) + COALESCE(ca.SilverBadges, 0) + COALESCE(ca.BronzeBadges, 0)) AS TotalBadges,
        DENSE_RANK() OVER (ORDER BY COALESCE(ca.GoldBadges, 0) DESC, COALESCE(ca.SilverBadges, 0) DESC) AS BadgesRank
    FROM Combined_Analysis ca
)
SELECT 
    *,
    CASE 
        WHEN TotalPosts > 100 THEN 'Active User'
        WHEN TotalPosts BETWEEN 50 AND 100 THEN 'Moderately Active User'
        ELSE 'Less Active User'
    END AS ActivityLevel
FROM User_Metrics
WHERE Reputation > 1000
ORDER BY Reputation DESC, ActivityLevel;
