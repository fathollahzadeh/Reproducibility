WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
), 
PostStats AS (
    SELECT 
        p.OwnerUserId, 
        COUNT(p.Id) AS TotalPosts, 
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),
CombinedStats AS (
    SELECT 
        u.DisplayName,
        ur.Reputation,
        ps.TotalPosts,
        ps.TotalAnswers,
        ps.TotalQuestions,
        COALESCE((SELECT SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) 
                    FROM Votes v 
                    WHERE v.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)), 0) AS TotalUpvotes
    FROM Users u
    JOIN UserReputation ur ON u.Id = ur.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    WHERE ur.Reputation > 1000
)
SELECT 
    cs.DisplayName,
    cs.Reputation,
    cs.TotalPosts,
    cs.TotalAnswers,
    cs.TotalQuestions,
    cs.TotalUpvotes,
    CASE 
        WHEN cs.TotalPosts IS NULL THEN 'No Posts Yet'
        WHEN cs.TotalQuestions > 0 THEN 'Active Questioner'
        WHEN cs.TotalAnswers > 0 THEN 'Active Responder'
        ELSE 'Inactive'
    END AS ActivityStatus
FROM CombinedStats cs
WHERE cs.TotalPosts > (
    SELECT AVG(TotalPosts) FROM PostStats
)
ORDER BY cs.Reputation DESC
LIMIT 10;