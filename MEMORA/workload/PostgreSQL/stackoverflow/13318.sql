
WITH UsersAggregate AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(*) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UsersAggregate
    WHERE 
        PostCount > 0
)
SELECT 
    u.DisplayName,
    t.Reputation,
    t.PostCount,
    t.TotalViews,
    t.TotalScore,
    t.ScoreRank
FROM 
    TopUsers t
JOIN 
    Users u ON t.UserId = u.Id
WHERE 
    t.ScoreRank <= 10
ORDER BY 
    t.ScoreRank;
