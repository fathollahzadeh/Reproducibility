WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, 
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
           u.DisplayName AS OwnerDisplayName, 
           COUNT(c.Id) AS CommentCount,
           (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
           (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount,
           ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN unnest(string_to_array(p.Tags, ',')) AS tag_names(tag) ON true
    LEFT JOIN Tags t ON t.TagName = tag_names.tag
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT * FROM RankedPosts WHERE Rank <= 10
)
SELECT tp.Id, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, 
       tp.OwnerDisplayName, tp.CommentCount, 
       tp.UpVoteCount, tp.DownVoteCount, 
       STRING_AGG(DISTINCT tag, ', ') AS Tags
FROM TopPosts tp
JOIN LATERAL (
    SELECT DISTINCT unnest(tp.Tags) AS tag
) AS t ON true
GROUP BY tp.Id, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, 
         tp.OwnerDisplayName, tp.CommentCount, 
         tp.UpVoteCount, tp.DownVoteCount
ORDER BY tp.Score DESC, tp.ViewCount DESC;