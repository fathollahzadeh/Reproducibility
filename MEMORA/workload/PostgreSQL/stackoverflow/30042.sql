
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.PostTypeId = 1  
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastCloseDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenDate
    FROM PostHistory ph
    GROUP BY ph.PostId
),
CommentsAggregate AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM Comments c
    GROUP BY c.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    rp.Score,
    rp.ViewCount,
    ur.DisplayName AS OwnerName,
    ur.Reputation AS OwnerReputation,
    ur.BadgeCount,
    COALESCE(ps.EditCount, 0) AS PostEditCount,
    ps.LastCloseDate,
    ps.LastReopenDate,
    COALESCE(ca.CommentCount, 0) AS TotalComments,
    ca.LastCommentDate
FROM RankedPosts rp
JOIN UserReputation ur ON ur.UserId = rp.OwnerUserId
LEFT JOIN PostHistorySummary ps ON ps.PostId = rp.PostId
LEFT JOIN CommentsAggregate ca ON ca.PostId = rp.PostId
WHERE rp.PostRank = 1  
ORDER BY ur.Reputation DESC, rp.ViewCount DESC
LIMIT 100;
