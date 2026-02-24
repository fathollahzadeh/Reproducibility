WITH RecentPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName AS OwnerDisplayName
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' AND p.PostTypeId = 1
),
PostStats AS (
    SELECT rp.Id, rp.Title, rp.OwnerDisplayName, rp.ViewCount, rp.Score, 
           COUNT(c.Id) AS CommentCount, 
           COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
           COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount
    FROM RecentPosts rp
    LEFT JOIN Comments c ON rp.Id = c.PostId
    LEFT JOIN Votes v ON rp.Id = v.PostId
    GROUP BY rp.Id, rp.Title, rp.OwnerDisplayName, rp.ViewCount, rp.Score
),
RankedPosts AS (
    SELECT ps.*, 
           RANK() OVER (ORDER BY ps.Score DESC, ps.ViewCount DESC) AS RankScore,
           RANK() OVER (ORDER BY ps.CommentCount DESC) AS RankComments
    FROM PostStats ps
)
SELECT rp.Id, rp.Title, rp.OwnerDisplayName, rp.ViewCount, rp.Score, 
       rp.CommentCount, rp.UpVoteCount, rp.DownVoteCount, 
       rp.RankScore, rp.RankComments
FROM RankedPosts rp
WHERE rp.RankScore <= 10 OR rp.RankComments <= 10
ORDER BY rp.RankScore, rp.RankComments;