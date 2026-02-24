WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScoreCount,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
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
        PositiveScoreCount,
        NegativeScoreCount,
        AverageScore,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS UserRank
    FROM 
        UserPostStats
    WHERE 
        TotalPosts > 0
)

SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.PositiveScoreCount,
    tu.NegativeScoreCount,
    tu.AverageScore,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN tu.AverageScore IS NULL THEN 'No Score' 
        WHEN tu.AverageScore > 0 THEN 'Positive'
        ELSE 'Negative' 
    END AS ScoreCategory
FROM 
    TopUsers tu
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) b ON tu.UserId = b.UserId
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tu.TotalPosts DESC;
