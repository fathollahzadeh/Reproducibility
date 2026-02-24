
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > '2023-01-01'
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - u.CreationDate)) / 86400) AS AvgDaysSinceCreation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
RecentClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.CreationDate AS ClosedDate,
        c.Name AS CloseReason,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    LEFT JOIN 
        CloseReasonTypes c ON CAST(ph.Comment AS INTEGER) = c.Id
    WHERE 
        ph.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
)
SELECT 
    u.DisplayName,
    u.Reputation,
    um.TotalPosts,
    um.TotalScore,
    um.AvgDaysSinceCreation,
    rp.PostId,
    rp.Title AS RecentPostTitle,
    rp.PostRank,
    rcp.Title AS ClosedPostTitle,
    rcp.ClosedDate,
    rcp.CloseReason
FROM 
    Users u
LEFT JOIN 
    UserMetrics um ON u.Id = um.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN 
    RecentClosedPosts rcp ON u.Id = rcp.OwnerUserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.Reputation DESC, 
    um.TotalPosts DESC
LIMIT 10;
