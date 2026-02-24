WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Location,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.LastAccessDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Location
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        ph.UserDisplayName AS ClosedBy,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
),
PostStatistics AS (
    SELECT 
        rp.Title,
        rp.ViewCount,
        a.DisplayName AS OwnerDisplayName,
        a.BadgeCount,
        cp.ClosedDate,
        cp.ClosedBy,
        cp.CloseReason,
        CASE 
            WHEN cp.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus
    FROM 
        RankedPosts rp
    JOIN 
        ActiveUsers a ON rp.OwnerUserId = a.UserId
    LEFT JOIN 
        ClosedPosts cp ON rp.Id = cp.PostId
)
SELECT 
    ps.Title,
    ps.ViewCount,
    ps.OwnerDisplayName,
    ps.BadgeCount,
    ps.ClosedDate,
    ps.ClosedBy,
    ps.CloseReason,
    ps.PostStatus
FROM 
    PostStatistics ps
WHERE 
    ps.PostStatus = 'Active'
ORDER BY 
    ps.ViewCount DESC
LIMIT 10;