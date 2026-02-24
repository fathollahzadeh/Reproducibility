WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        TotalUpVotes,
        TotalDownVotes,
        TotalBadges,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
),
RecentActivePosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS RecentPosts,
        MAX(p.LastActivityDate) AS MostRecentActivity
    FROM Posts p
    WHERE p.LastActivityDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY p.OwnerUserId
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.TotalScore,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    tu.TotalBadges,
    rap.RecentPosts,
    rap.MostRecentActivity
FROM TopUsers tu
LEFT JOIN RecentActivePosts rap ON tu.UserId = rap.OwnerUserId
WHERE tu.ReputationRank <= 10
ORDER BY tu.Reputation DESC;