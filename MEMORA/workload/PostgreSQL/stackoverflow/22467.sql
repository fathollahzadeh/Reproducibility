WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
), 
PostHistorySummary AS (
    SELECT
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS PostClosure
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    ur.Reputation,
    ur.TotalBadges,
    COALESCE(phs.CloseCount, 0) AS TotalCloseActions,
    COALESCE(phs.DeleteCount, 0) AS TotalDeleteActions,
    ua.DisplayName,
    ua.TotalBounty,
    ua.PostCount,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Latest Post'
        ELSE 'Older Post'
    END AS PostStatus,
    CASE 
        WHEN phs.PostClosure > 0 THEN 'Closed'
        ELSE 'Open'
    END AS ClosureStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
JOIN 
    UserActivity ua ON rp.OwnerUserId = ua.UserId
WHERE 
    rp.ViewCount > (
        SELECT AVG(ViewCount) 
        FROM Posts
    )
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;