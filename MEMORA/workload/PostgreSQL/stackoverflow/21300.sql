WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(b.Class) AS BadgeCount
    FROM Users u
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS TotalComments
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id
),
CloseReasonCounts AS (
    SELECT 
        ph.PostId,
        ph.Comment as CloseReason,
        COUNT(ph.Id) AS ReasonCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 
    GROUP BY ph.PostId, ph.Comment
)
SELECT 
    up.DisplayName,
    up.CommentCount,
    up.UpVoteCount,
    up.DownVoteCount,
    COALESCE(pc.TotalComments, 0) AS TotalComments,
    rp.Title,
    rp.CreationDate,
    rp.Score AS PostScore,
    rp.ViewCount,
    cr.CloseReason,
    COALESCE(cr.ReasonCount, 0) AS CloseReasonCount
FROM UserActivity up
JOIN RankedPosts rp ON up.UserId = rp.PostId
LEFT JOIN PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN CloseReasonCounts cr ON rp.PostId = cr.PostId
WHERE up.CommentCount > 10 
  AND rp.PostRank <= 3 
  AND (up.DownVoteCount IS NULL OR up.DownVoteCount < 5)
ORDER BY rp.ViewCount DESC, up.UpVoteCount DESC
LIMIT 100;