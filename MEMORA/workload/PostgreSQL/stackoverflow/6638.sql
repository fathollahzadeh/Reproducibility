
WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.Score, p.CreationDate, p.Tags, 
           ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS rn,
           COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1 
      AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.Score, p.CreationDate, p.Tags
), TopRanked AS (
    SELECT rp.*, 
           (SELECT AVG(rp2.Score) 
            FROM RankedPosts rp2 
            WHERE rp2.Tags = rp.Tags) AS AvgScoreByTag
    FROM RankedPosts rp
    WHERE rn <= 5
)
SELECT tr.Title, tr.Score, tr.CreationDate, tr.Tags, 
       tr.CommentCount, tr.AvgScoreByTag
FROM TopRanked tr
ORDER BY tr.Tags, tr.Score DESC;
