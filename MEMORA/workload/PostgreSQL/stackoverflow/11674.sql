WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),

TopUsers AS (
    SELECT 
        UserId,
        PostCount,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM UserPostStats
)

SELECT 
    u.DisplayName,
    u.Reputation,
    tus.PostCount,
    tus.TotalViews,
    tus.TotalScore,
    tus.ScoreRank,
    tus.ViewRank
FROM TopUsers tus
JOIN Users u ON tus.UserId = u.Id
ORDER BY tus.ScoreRank, tus.ViewRank;