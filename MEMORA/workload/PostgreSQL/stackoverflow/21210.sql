WITH UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.UpVotes - u.DownVotes AS NetVotes,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON u.Id = b.UserId
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
PostActions AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN 'Closed'
            WHEN ph.PostHistoryTypeId = 12 THEN 'Deleted'
            WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened'
            ELSE 'Other'
        END AS ActionType
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= cast('2024-10-01' as date) - INTERVAL '90 days'
),
AggregatedActions AS (
    SELECT 
        UserId,
        COUNT(*) FILTER (WHERE ActionType = 'Closed') AS ClosedCount,
        COUNT(*) FILTER (WHERE ActionType = 'Deleted') AS DeletedCount,
        COUNT(*) FILTER (WHERE ActionType = 'Reopened') AS ReopenedCount
    FROM 
        PostActions
    GROUP BY 
        UserId
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.NetVotes,
    us.BadgeCount,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    COALESCE(aa.ClosedCount, 0) AS TotalClosed,
    COALESCE(aa.DeletedCount, 0) AS TotalDeleted,
    COALESCE(aa.ReopenedCount, 0) AS TotalReopened,
    CASE 
        WHEN us.Reputation >= 1000 AND us.BadgeCount > 5 THEN 'Veteran'
        WHEN us.Reputation < 1000 AND us.BadgeCount < 3 THEN 'Newbie'
        ELSE 'Intermediate'
    END AS UserType
FROM 
    UserScores us
JOIN 
    RecentPosts rp ON us.UserId = rp.OwnerUserId
LEFT JOIN 
    AggregatedActions aa ON us.UserId = aa.UserId
WHERE 
    us.Reputation > 0
ORDER BY 
    us.Reputation DESC, rp.ViewCount DESC
LIMIT 50;