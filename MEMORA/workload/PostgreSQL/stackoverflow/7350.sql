WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1
      AND p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS AvgUpVotes,
        AVG(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS AvgDownVotes
    FROM RankedPosts rp
    LEFT JOIN Comments c ON c.PostId = rp.PostId
    LEFT JOIN Votes v ON v.PostId = rp.PostId
    GROUP BY rp.PostId, rp.Title, rp.ViewCount, rp.Score, rp.OwnerDisplayName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.OwnerDisplayName,
    ps.CommentCount,
    ps.VoteCount,
    ps.AvgUpVotes,
    ps.AvgDownVotes,
    CASE 
        WHEN ps.Score > 100 THEN 'High Score'
        WHEN ps.Score BETWEEN 50 AND 100 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM PostStatistics ps
WHERE ps.CommentCount > 0
ORDER BY ps.ViewCount DESC, ps.Score DESC
LIMIT 100;