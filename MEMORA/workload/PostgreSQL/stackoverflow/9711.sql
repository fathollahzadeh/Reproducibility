WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 24) 
    GROUP BY 
        ph.PostId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    up.TotalPosts,
    up.TotalScore,
    up.TotalViews,
    rp.Title,
    rp.CreationDate,
    rp.Score AS PostScore,
    rp.ViewCount AS PostViewCount,
    COALESCE(ph.EditCount, 0) AS TotalEdits
FROM 
    UserStatistics up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    PostHistorySummary ph ON rp.PostId = ph.PostId
ORDER BY 
    up.TotalScore DESC, up.Reputation DESC;