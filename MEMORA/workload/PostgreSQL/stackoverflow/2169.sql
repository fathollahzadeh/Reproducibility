
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(
            (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0
        ) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.Score > 10
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
)
SELECT 
    tu.DisplayName,
    COUNT(rp.PostId) AS PostCount,
    SUM(rp.ViewCount) AS TotalViews,
    AVG(rp.Score) AS AverageScore,
    STRING_AGG(rp.Title, ', ') AS PostTitles,
    MAX(rp.CreationDate) AS LastPostDate,
    CASE 
        WHEN MAX(rp.CreationDate) < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' THEN 'Inactive' 
        ELSE 'Active' 
    END AS ActivityStatus
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId
WHERE 
    tu.UserRank <= 10
GROUP BY 
    tu.DisplayName
ORDER BY 
    PostCount DESC;
