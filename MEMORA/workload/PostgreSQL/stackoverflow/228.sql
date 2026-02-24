
WITH UserReputation AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        CASE 
            WHEN Reputation >= 1000 THEN 'High'
            WHEN Reputation >= 100 THEN 'Medium'
            ELSE 'Low' 
        END AS ReputationLevel
    FROM Users
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM Posts p
    GROUP BY p.OwnerUserId
),
RecentActivity AS (
    SELECT 
        p.OwnerUserId,
        MAX(p.LastActivityDate) AS LastActivityDate
    FROM Posts p
    GROUP BY p.OwnerUserId
),
TopUsers AS (
    SELECT 
        ur.DisplayName,
        ur.ReputationLevel,
        ps.TotalPosts,
        ps.TotalQuestions,
        ps.TotalAnswers,
        ra.LastActivityDate,
        ur.Id AS OwnerUserId
    FROM UserReputation ur
    JOIN PostStats ps ON ur.Id = ps.OwnerUserId
    JOIN RecentActivity ra ON ur.Id = ra.OwnerUserId
    WHERE ur.ReputationLevel = 'High'
      AND ps.TotalPosts > 5
      AND ra.LastActivityDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
)
SELECT 
    t.DisplayName,
    t.ReputationLevel,
    t.TotalPosts,
    t.TotalQuestions,
    t.TotalAnswers,
    COALESCE(pv.UpVotes, 0) AS RecentUpVotes,
    COALESCE(cv.CloseVotes, 0) AS RecentCloseVotes
FROM TopUsers t
LEFT JOIN (
    SELECT 
        p.OwnerUserId,
        COUNT(v.Id) AS UpVotes
    FROM Posts p
    JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    GROUP BY p.OwnerUserId
) pv ON t.OwnerUserId = pv.OwnerUserId
LEFT JOIN (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS CloseVotes
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.UserId
) cv ON t.OwnerUserId = cv.UserId
ORDER BY t.TotalPosts DESC, t.ReputationLevel;
