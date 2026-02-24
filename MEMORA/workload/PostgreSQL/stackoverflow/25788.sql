WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(CASE WHEN p.Score > 0 THEN p.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 0
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY TotalScore DESC, TotalPosts DESC) AS ScoreRank
    FROM UserStatistics
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.TotalPosts,
    t.TotalQuestions,
    t.TotalAnswers,
    t.TotalScore,
    t.GoldBadges,
    t.SilverBadges,
    t.BronzeBadges,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = t.UserId AND p.CreationDate BETWEEN cast('2024-10-01' as date) - INTERVAL '30 days' AND cast('2024-10-01' as date)) AS RecentPosts,
    (SELECT COUNT(*) FROM Comments c WHERE c.UserId = t.UserId AND c.CreationDate BETWEEN cast('2024-10-01' as date) - INTERVAL '30 days' AND cast('2024-10-01' as date)) AS RecentComments,
    (SELECT COUNT(*) FROM Votes v WHERE v.UserId = t.UserId AND v.CreationDate BETWEEN cast('2024-10-01' as date) - INTERVAL '30 days' AND cast('2024-10-01' as date)) AS RecentVotes
FROM TopUsers t
WHERE t.ScoreRank <= 10
ORDER BY t.TotalScore DESC, t.TotalPosts DESC;