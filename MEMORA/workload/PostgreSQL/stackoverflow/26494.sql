
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(
            (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 
            0
        ) AS CommentCount,
        COALESCE(
            (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2),
            0
        ) AS UpvoteCount,
        RANK() OVER (ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Title IS NOT NULL
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpvoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10 
),
TagsAggregated AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(DISTINCT LOWER(TRIM(value)), ', ') AS Tags
    FROM 
        Posts p,
        UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags)-2), '><')) AS value
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.UpvoteCount,
    ta.Tags
FROM 
    TopPosts tp
LEFT JOIN 
    TagsAggregated ta ON tp.PostId = ta.PostId
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
