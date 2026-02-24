WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1 
        AND p.CreationDate >= '2022-01-01' 
),
TopPosts AS (
    SELECT *
    FROM RankedPosts
    WHERE TagRank <= 5 
),
PostComments AS (
    SELECT
        pc.PostId,
        COUNT(*) AS CommentCount,
        STRING_AGG(pc.Text, ' | ') AS CommentTexts
    FROM
        Comments pc
    GROUP BY
        pc.PostId
)
SELECT
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.Tags,
    tp.CreationDate,
    tp.Score,
    tp.OwnerDisplayName,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    COALESCE(pc.CommentTexts, 'No comments') AS CommentTexts
FROM
    TopPosts tp
LEFT JOIN
    PostComments pc ON tp.PostId = pc.PostId
ORDER BY
    tp.Tags, tp.Score DESC;