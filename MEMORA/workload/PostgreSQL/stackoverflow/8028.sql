WITH RankedPosts AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.CreationDate, 
           p.Score, 
           p.OwnerUserId, 
           u.DisplayName AS OwnerDisplayName,
           RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
           COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= '2022-01-01'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId, u.DisplayName, p.PostTypeId
),
HighScorePosts AS (
    SELECT rp.PostId, 
           rp.Title, 
           rp.CreationDate, 
           rp.Score, 
           rp.OwnerDisplayName, 
           rp.CommentCount
    FROM RankedPosts rp
    WHERE rp.Rank <= 10
),
TopTags AS (
    SELECT t.TagName, 
           COUNT(pt.Id) AS PostCount
    FROM Tags t
    JOIN Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
    ORDER BY PostCount DESC
    LIMIT 5
)
SELECT hsp.Title, 
       hsp.Score, 
       hsp.CommentCount, 
       tt.TagName
FROM HighScorePosts hsp
CROSS JOIN TopTags tt
ORDER BY hsp.Score DESC, tt.PostCount DESC;
