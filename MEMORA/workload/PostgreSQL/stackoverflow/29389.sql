
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= '2023-01-01' 
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Author,
        rp.Score,
        rp.ViewCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10 
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Body,
        tp.CreationDate,
        tp.Author,
        tp.Score,
        tp.ViewCount,
        tp.Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS RelatedTags
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    LEFT JOIN 
        Tags t ON t.TagName = ANY(string_to_array(tp.Tags, '><')) 
    GROUP BY 
        tp.PostId, tp.Title, tp.Body, tp.CreationDate, tp.Author, tp.Score, tp.ViewCount, tp.Tags
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.CreationDate,
    pd.Author,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.VoteCount,
    pd.RelatedTags,
    pt.Name AS PostType
FROM 
    PostDetails pd
JOIN 
    PostTypes pt ON pd.Tags LIKE CONCAT('%', pt.Name, '%') 
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
