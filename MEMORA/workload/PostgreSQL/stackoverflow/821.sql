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
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions
    FROM Posts p
    GROUP BY p.OwnerUserId
), 
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ps.TotalPosts,
        ps.TotalAnswers,
        ps.TotalQuestions,
        DENSE_RANK() OVER (ORDER BY ur.Reputation DESC) AS UserRank
    FROM UserReputation ur
    LEFT JOIN PostStats ps ON ur.UserId = ps.OwnerUserId
    WHERE ur.Reputation > 1000
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalAnswers,
    tu.TotalQuestions,
    COALESCE(tu.TotalQuestions - tu.TotalAnswers, 0) AS UnansweredQuestions,
    CASE 
        WHEN tu.UserRank <= 10 THEN 'Top 10 User'
        ELSE 'Not in Top 10'
    END AS UserCategory,
    (SELECT COUNT(b.Id) FROM Badges b WHERE b.UserId = tu.UserId) AS TotalBadges,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Tags t 
     JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%' 
     WHERE p.OwnerUserId = tu.UserId) AS PopularTags
FROM TopUsers tu
WHERE tu.TotalPosts IS NOT NULL
ORDER BY tu.UserRank;
