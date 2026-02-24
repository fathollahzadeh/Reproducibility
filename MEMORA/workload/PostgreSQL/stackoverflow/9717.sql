WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM UserPostStats
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.Questions,
    tu.Answers,
    tu.TotalViews,
    tu.TotalScore,
    pht.Name AS RecentActivity,
    COUNT(ph.Id) AS ActivityCount
FROM TopUsers tu
LEFT JOIN PostHistory ph ON tu.UserId = ph.UserId
JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE tu.ScoreRank <= 10 OR tu.PostRank <= 10
GROUP BY 
    tu.UserId, tu.DisplayName, tu.TotalPosts, tu.Questions, tu.Answers, 
    tu.TotalViews, tu.TotalScore, pht.Name
ORDER BY 
    tu.TotalScore DESC, 
    tu.TotalPosts DESC;
