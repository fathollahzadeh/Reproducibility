WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScores
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
        us.TotalViews,
        us.PostCount,
        us.PositiveScores,
        ROW_NUMBER() OVER (ORDER BY us.TotalViews DESC) AS UserRank
    FROM 
        UserStats us
    WHERE 
        us.PostCount > 0
)
SELECT 
    tp.UserRank,
    u.DisplayName,
    tp.TotalViews,
    tp.PostCount,
    tp.PositiveScores,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate
FROM 
    TopUsers tp
LEFT JOIN 
    Users u ON tp.UserId = u.Id
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.PostId
WHERE 
    tp.UserRank <= 10
ORDER BY 
    tp.UserRank, rp.Score DESC NULLS LAST;