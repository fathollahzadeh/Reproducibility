WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.ViewCount IS NULL THEN 0 ELSE p.ViewCount END) AS TotalViews,
        SUM(CASE WHEN p.Score IS NULL THEN 0 ELSE p.Score END) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.PostCount,
        us.TotalViews,
        us.TotalScore,
        DENSE_RANK() OVER (ORDER BY us.TotalScore DESC) AS Rank
    FROM 
        UserStats us
    WHERE 
        us.PostCount > 5
)
SELECT 
    tu.DisplayName,
    tu.TotalScore,
    tu.TotalViews,
    RP.Title AS TopPostTitle,
    RP.CreationDate AS TopPostDate
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts RP ON tu.UserId = RP.OwnerUserId AND RP.rn = 1
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.TotalScore DESC, tu.TotalViews DESC;
