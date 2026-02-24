
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        TotalScore,
        AvgViewCount,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserPostStats
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.Questions,
    tu.Answers,
    tu.TotalScore,
    tu.AvgViewCount,
    CAST(u.CreationDate AS VARCHAR(10)) AS AccountCreationDate,
    CASE 
        WHEN tu.ScoreRank <= 10 THEN 'Top Contributor' 
        ELSE 'Contributor' 
    END AS ContributorStatus
FROM 
    TopUsers tu
JOIN 
    Users u ON tu.UserId = u.Id
WHERE 
    tu.TotalPosts > 5
ORDER BY 
    tu.ScoreRank;
