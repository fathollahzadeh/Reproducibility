
WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.Score,
           p.ViewCount,
           u.DisplayName AS OwnerDisplayName,
           COUNT(DISTINCT c.Id) AS CommentCount,
           COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVoteCount,
           COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVoteCount,
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName, p.PostTypeId, p.CreationDate
),
TopPosts AS (
    SELECT PostId,
           Title,
           Score,
           ViewCount,
           OwnerDisplayName,
           CommentCount,
           UpVoteCount,
           DownVoteCount
    FROM RankedPosts
    WHERE Rank <= 5
)
SELECT tp.*,
       CASE 
           WHEN tp.UpVoteCount > tp.DownVoteCount THEN 'More Upvotes' 
           WHEN tp.UpVoteCount < tp.DownVoteCount THEN 'More Downvotes' 
           ELSE 'Equal' 
       END AS VoteTrend
FROM TopPosts tp
ORDER BY tp.Score DESC, tp.ViewCount DESC;
