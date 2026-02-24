
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        DENSE_RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
FilteredBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM Badges b
    WHERE b.Class = 1 
    GROUP BY b.UserId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM Comments c
    GROUP BY c.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY ph.PostId, ph.CreationDate
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.Rank,
    pb.BadgeCount,
    pc.CommentCount,
    cp.CloseCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) - 
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes
FROM RankedPosts rp
LEFT JOIN FilteredBadges pb ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = pb.UserId)
LEFT JOIN PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN Votes v ON rp.PostId = v.PostId
GROUP BY rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.Rank, pb.BadgeCount, pc.CommentCount, cp.CloseCount
HAVING rp.Rank <= 10 
ORDER BY rp.Rank, rp.Score DESC;
