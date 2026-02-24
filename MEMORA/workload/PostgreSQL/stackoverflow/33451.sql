WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
PostStatistics AS (
    SELECT 
        rp.OwnerUserId,
        COUNT(rp.Id) AS TotalQuestions,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.ViewCount) AS AverageViewCount
    FROM 
        RankedPosts rp
    GROUP BY 
        rp.OwnerUserId
),
TopUsers AS (
    SELECT 
        ps.OwnerUserId,
        ps.TotalQuestions,
        ps.TotalScore,
        ps.AverageViewCount,
        RANK() OVER (ORDER BY ps.TotalScore DESC) AS UserRank
    FROM 
        PostStatistics ps
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    tu.TotalQuestions,
    tu.TotalScore,
    tu.AverageViewCount,
    tu.UserRank
FROM 
    Users u
LEFT JOIN 
    TopUsers tu ON u.Id = tu.OwnerUserId
WHERE 
    (u.Reputation >= 100 OR tu.TotalQuestions IS NOT NULL) 
ORDER BY 
    tu.UserRank ASC NULLS LAST;