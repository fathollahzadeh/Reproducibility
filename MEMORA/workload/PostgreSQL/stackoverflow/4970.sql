WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        AVG(p.Score) AS AvgScore,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalAnswers,
        TotalQuestions,
        AvgScore,
        TotalUpVotes,
        TotalDownVotes,
        RANK() OVER (ORDER BY TotalUpVotes DESC) AS Ranking
    FROM UserStats
)

SELECT 
    tu.DisplayName,
    CASE 
        WHEN tu.TotalPosts > 100 THEN 'Veteran'
        WHEN tu.TotalPosts BETWEEN 51 AND 100 THEN 'Experienced'
        ELSE 'Novice' 
    END AS UserType,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.AvgScore,
    tu.Ranking
FROM TopUsers tu
WHERE 
    tu.Ranking <= 10
    OR (SELECT COUNT(*) FROM Badges b WHERE b.UserId = tu.UserId AND b.Class = 1) > 0
ORDER BY tu.Ranking, tu.TotalPosts DESC;