WITH RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - interval '30 days'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastUpdated
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.Comment AS CloseReason,
        ph.CreationDate AS CloseDate
    FROM 
        Posts p 
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
)
SELECT 
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    rp.Score AS RecentPostScore,
    rp.ViewCount AS RecentPostViews,
    tu.DisplayName AS TopUserDisplayName,
    tu.TotalBounty AS TopUserTotalBounty,
    phc.HistoryCount AS PostHistoryCount,
    cp.CloseReason AS ClosedPostReason,
    cp.CloseDate AS ClosedPostDate
FROM 
    RecentPosts rp 
LEFT JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId AND tu.UserRank <= 10
LEFT JOIN 
    PostHistoryCounts phc ON rp.Id = phc.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.CreationDate DESC;