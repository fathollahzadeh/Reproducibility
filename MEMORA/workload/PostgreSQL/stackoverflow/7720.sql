WITH RecentPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, 
           u.DisplayName AS OwnerDisplayName, 
           COUNT(c.Id) AS CommentCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
RankedPosts AS (
    SELECT rp.*, 
           RANK() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS Rank
    FROM RecentPosts rp
)
SELECT r.Title, r.OwnerDisplayName, r.CreationDate, r.Score, r.ViewCount, 
       r.CommentCount, r.UpVotes, r.DownVotes, r.Rank
FROM RankedPosts r
WHERE r.Rank <= 10
ORDER BY r.Rank;