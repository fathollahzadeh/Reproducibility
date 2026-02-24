
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2022-01-01' 
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= '2022-01-01'
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5 
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalViews,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS ActiveRank
    FROM 
        TopUsers
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.Id) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
)
SELECT 
    au.DisplayName,
    au.TotalViews,
    au.PostCount,
    COALESCE(php.EditCount, 0) AS TotalEdits,
    COALESCE(lp.LinkCount, 0) AS LinkCount,
    rp.Rank
FROM 
    ActiveUsers au
LEFT JOIN 
    PostHistoryCounts php ON au.UserId = (SELECT p.OwnerUserId FROM Posts p WHERE p.Id = php.PostId)
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(L.Id) AS LinkCount
    FROM 
        PostLinks L
    GROUP BY 
        PostId
) lp ON lp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = au.UserId)
LEFT JOIN 
    RankedPosts rp ON rp.OwnerUserId = au.UserId
WHERE 
    au.ActiveRank <= 10 
ORDER BY 
    au.TotalViews DESC, au.DisplayName;
