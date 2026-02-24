WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(CAST(NULLIF(SUBSTRING(p.Body, 1, 100), '') AS VARCHAR), 'No content') AS Snippet
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.PostCount,
        ups.TotalScore,
        ups.TotalViews,
        RANK() OVER (ORDER BY ups.TotalScore DESC) AS UserRank
    FROM 
        UserPostStats ups
    WHERE 
        ups.PostCount > 0
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalScore,
    tu.TotalViews,
    rp.Title,
    rp.CreationDate,
    rp.Snippet
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.PostId
WHERE 
    tu.UserRank <= 10 
    AND rp.Rank = 1
ORDER BY 
    tu.TotalScore DESC, 
    rp.CreationDate DESC;