WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM Posts p
    WHERE p.PostTypeId = 1
      AND p.Score IS NOT NULL
),
UserVotes AS (
    SELECT 
        v.PostId,
        vt.Name AS VoteType,
        COUNT(*) AS VoteCount
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.PostId, vt.Name
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 
    GROUP BY ph.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    COALESCE(v.VoteCount, 0) AS TotalVotes,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    ub.BadgeCount,
    CASE 
        WHEN rp.ScoreRank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostRanking
FROM RankedPosts rp
JOIN Posts p ON rp.Id = p.Id
LEFT JOIN UserVotes v ON p.Id = v.PostId
LEFT JOIN ClosedPosts cp ON p.Id = cp.PostId
JOIN Users u ON p.OwnerUserId = u.Id
JOIN UserBadges ub ON u.Id = ub.UserId
WHERE p.ViewCount > 1000
  AND (p.AnswerCount IS NULL OR p.AnswerCount > 0)
ORDER BY p.Score DESC, p.CreationDate DESC
LIMIT 50;