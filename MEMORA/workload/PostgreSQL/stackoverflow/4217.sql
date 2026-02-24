WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
),
RankedUserStats AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        AvgReputation,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserPostStats
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.AvgReputation,
    CASE 
        WHEN u.TotalPosts > 50 THEN 'High Activity'
        WHEN u.TotalPosts BETWEEN 20 AND 50 THEN 'Moderate Activity'
        ELSE 'Low Activity'
    END AS ActivityLevel,
    (SELECT 
         COUNT(*) 
     FROM 
         Votes v 
     WHERE 
         v.UserId = u.UserId 
         AND v.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month') AS RecentVotes
FROM 
    RankedUserStats u
WHERE 
    u.TotalQuestions > 5
    AND u.TotalAnswers > 5
    AND NOT EXISTS (
        SELECT 1 
        FROM Badges b 
        WHERE b.UserId = u.UserId AND b.Class = 1
    )
ORDER BY 
    u.PostRank, u.AvgReputation DESC
LIMIT 10;