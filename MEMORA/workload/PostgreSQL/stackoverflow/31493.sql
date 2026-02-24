WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS NumberOfPosts,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.NumberOfPosts,
        us.TotalScore,
        us.AverageScore,
        RANK() OVER (ORDER BY us.TotalScore DESC) AS UserRank
    FROM 
        UserStats us
    WHERE 
        us.NumberOfPosts > 10 
)
SELECT 
    tu.DisplayName, 
    tu.NumberOfPosts, 
    tu.TotalScore, 
    tu.AverageScore,
    rp.Title AS TopPostTitle,
    rp.Score AS TopPostScore,
    rp.CreationDate AS TopPostCreationDate
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId AND rp.Rank = 1 
WHERE 
    tu.UserRank <= 10 
ORDER BY 
    tu.TotalScore DESC;