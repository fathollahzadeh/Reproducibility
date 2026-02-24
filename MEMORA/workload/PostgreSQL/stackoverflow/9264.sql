
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM RankedPosts
    WHERE Rank <= 10
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM Posts p
    JOIN UNNEST(string_to_array(p.Tags, '><')) AS tag ON TRUE
    JOIN Tags t ON t.TagName = TRIM(BOTH ' ' FROM tag)
    GROUP BY p.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    pt.Tags,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM TopPosts tp
LEFT JOIN Comments c ON tp.PostId = c.PostId
LEFT JOIN Votes v ON tp.PostId = v.PostId
LEFT JOIN PostTags pt ON tp.PostId = pt.PostId
GROUP BY tp.PostId, tp.Title, tp.Score, tp.ViewCount, tp.OwnerDisplayName, pt.Tags
ORDER BY tp.Score DESC, tp.ViewCount DESC;
