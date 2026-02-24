
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        ARRAY_LENGTH(STRING_TO_ARRAY(p.Tags, '><'), 1) AS TagCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Score,
        COUNT(c.Id) AS CommentCount,
        p.CreationDate
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.TagCount,
        rp.Score,
        rp.CommentCount,
        rp.CreationDate,
        RANK() OVER (ORDER BY rp.Score DESC, rp.CreationDate DESC) AS Rank
    FROM 
        RankedPosts rp
),
TaggedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Body,
        pd.TagCount,
        pd.Score,
        pd.CommentCount,
        pd.CreationDate,
        pd.Rank,
        t.TagName
    FROM 
        PostDetails pd
    JOIN 
        Posts p ON pd.PostId = p.Id
    CROSS JOIN 
        UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><')) AS tag_arr
    JOIN 
        Tags t ON t.TagName = tag_arr
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.TagCount,
    tp.Score,
    tp.CommentCount,
    tp.Rank,
    STRING_AGG(DISTINCT tp.TagName, ', ') AS Tags
FROM 
    TaggedPosts tp
GROUP BY 
    tp.PostId, tp.Title, tp.Body, tp.TagCount, tp.Score, tp.CommentCount, tp.Rank
ORDER BY 
    tp.Rank
LIMIT 10;
