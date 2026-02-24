WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
        AND p.PostTypeId = 1 
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.Views,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBountySpent
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (2,3)
    GROUP BY 
        u.Id, u.Reputation, u.Views
),

PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS IsClosed,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (11, 13) THEN 1 ELSE 0 END) AS IsReopened,
        COUNT(ph.Id) AS EditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.Score,
    rp.ViewCount,
    CASE 
        WHEN us.UserId IS NULL THEN 'Unregistered'
        ELSE u.DisplayName 
    END AS OwnerDisplayName,
    us.Reputation,
    us.Views,
    us.BadgeCount,
    us.TotalBountySpent,
    CASE 
        WHEN phs.IsClosed = 1 THEN 'Closed'
        WHEN phs.IsReopened = 1 THEN 'Reopened'
        ELSE 'Active'
    END AS PostStatus,
    phs.EditCount
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserStats us ON u.Id = us.UserId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.OwnerRank = 1 
    AND rp.Score > 0 
ORDER BY 
    rp.CreationDate DESC,
    us.Reputation DESC;