
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(p.Tags, '<>')) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 MONTH')
    GROUP BY
        p.Id, u.DisplayName, p.Title, p.Score, p.ViewCount, p.PostTypeId
),
TopPosts AS (
    SELECT
        PostId, Title, Score, ViewCount, OwnerDisplayName, CommentCount, Tags
    FROM
        RankedPosts
    WHERE
        Rank <= 10
)
SELECT
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.Tags,
    ph.CreationDate AS LastEditDate,
    ph.UserDisplayName AS LastEditor
FROM
    TopPosts tp
LEFT JOIN
    PostHistory ph ON tp.PostId = ph.PostId
WHERE
    ph.PostHistoryTypeId IN (4, 5) 
ORDER BY
    tp.Score DESC, tp.ViewCount DESC;
