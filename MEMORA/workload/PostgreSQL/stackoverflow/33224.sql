WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
      AND p.Score > 0
),
MostCommentedPosts AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM Comments 
    GROUP BY PostId
    HAVING COUNT(*) > 5
),
PostWithBadges AS (
    SELECT 
        p.Id AS PostId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS MaxBadgeClass
    FROM Posts p
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE b.Date >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.Id
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11, 12) THEN 1 ELSE 0 END) AS IsClosedOrDeleted
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    COALESCE(mcp.CommentCount, 0) AS TopCommentCount,
    COALESCE(pwb.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(pwb.MaxBadgeClass, 0) AS UserMaxBadgeClass,
    COALESCE(pht.HistoryCount, 0) AS PostHistoryCount,
    CASE 
        WHEN pht.IsClosedOrDeleted = 1 THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus
FROM RankedPosts rp
LEFT JOIN MostCommentedPosts mcp ON rp.PostId = mcp.PostId
LEFT JOIN PostWithBadges pwb ON rp.PostId = pwb.PostId
LEFT JOIN PostHistoryStats pht ON rp.PostId = pht.PostId
WHERE rp.RankScore <= 10
ORDER BY rp.Score DESC, rp.PostId;