WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY u.Location ORDER BY p.Score DESC) AS RankByLocation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND   
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByLocation <= 5  
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, '; ') AS CommentTexts
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.Body,
    trp.Tags,
    trp.OwnerDisplayName,
    trp.CreationDate,
    trp.ViewCount,
    trp.Score,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    COALESCE(pc.CommentTexts, 'No Comments') AS SampleComments
FROM 
    TopRankedPosts trp
LEFT JOIN 
    PostComments pc ON trp.PostId = pc.PostId
ORDER BY 
    trp.Score DESC, trp.ViewCount DESC;