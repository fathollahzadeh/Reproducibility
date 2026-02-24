WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
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
        PostCount,
        TotalViews,
        TotalScore,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS ViewRank,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserPostStats
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalViews,
    tu.TotalScore,
    CASE 
        WHEN tu.ViewRank < 11 THEN 'Top Viewers'
        ELSE 'Average Viewers'
    END AS ViewStatus,
    CASE 
        WHEN tu.ScoreRank < 11 THEN 'Top Scorers'
        ELSE 'Average Scorers'
    END AS ScoreStatus,
    COALESCE(b.BadgeCount, 0) AS NumberOfBadges
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
    tu.PostCount > 0
ORDER BY 
    tu.TotalScore DESC, tu.TotalViews DESC
LIMIT 20;