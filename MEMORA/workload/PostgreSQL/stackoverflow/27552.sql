
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        p.PostTypeId,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'  
)

SELECT
    r.PostId,
    r.Title,
    r.OwnerDisplayName,
    r.ViewCount,
    r.AnswerCount,
    r.CommentCount,
    r.FavoriteCount,
    CASE
        WHEN r.ViewRank <= 5 THEN 'Top 5'
        WHEN r.ViewRank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS RankCategory,
    STRING_AGG(pt.Name, ', ') AS PostTypeNames,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    COUNT(ph.Id) AS EditCount
FROM
    RankedPosts r
LEFT JOIN
    PostTypes pt ON r.PostTypeId = pt.Id
LEFT JOIN
    Posts p ON r.PostId = p.Id
LEFT JOIN
    Tags t ON t.WikiPostId = p.Id OR t.ExcerptPostId = p.Id
LEFT JOIN
    PostHistory ph ON ph.PostId = p.Id AND ph.PostHistoryTypeId IN (4, 5, 6)
GROUP BY
    r.PostId, r.Title, r.OwnerDisplayName, r.ViewCount, r.AnswerCount, r.CommentCount, r.FavoriteCount, r.ViewRank, r.PostTypeId
ORDER BY
    r.ViewCount DESC;
