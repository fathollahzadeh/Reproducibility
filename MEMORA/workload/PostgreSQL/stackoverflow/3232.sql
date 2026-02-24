WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(p.Score) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        us.TotalPosts,
        us.TotalScore,
        us.AvgScore,
        RANK() OVER (ORDER BY us.TotalScore DESC) AS ScoreRank
    FROM 
        Users u
    JOIN 
        UserStats us ON u.Id = us.UserId
    WHERE 
        us.TotalPosts > 0
        AND us.AvgScore IS NOT NULL
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalScore,
    tu.AvgScore,
    rp.Title AS TopPostTitle,
    rp.Score AS TopPostScore,
    rp.CreationDate AS TopPostDate
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rp ON tu.Id = rp.OwnerUserId AND rp.PostRank = 1
WHERE 
    tu.ScoreRank <= 10
ORDER BY 
    tu.TotalScore DESC