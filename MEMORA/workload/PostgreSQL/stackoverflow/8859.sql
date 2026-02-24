
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 5
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.UserId) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalViews,
    tu.TotalScore,
    tu.PostCount,
    COUNT(rp.PostId) AS NumberOfTopPosts,
    SUM(COALESCE(phs.EditCount, 0)) AS TotalEdits,
    MAX(phs.LastEditDate) AS MostRecentEdit
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId AND rp.PostRank <= 3
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
GROUP BY 
    tu.UserId, tu.DisplayName, tu.TotalViews, tu.TotalScore, tu.PostCount
ORDER BY 
    tu.TotalScore DESC, tu.TotalViews DESC;
