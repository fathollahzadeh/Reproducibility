WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2022-01-01' AND 
        p.Score > 0
),
TopRankedPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        ViewCount, 
        Score, 
        OwnerDisplayName 
    FROM 
        RankedPosts 
    WHERE 
        RankScore <= 10
),
PostComments AS (
    SELECT 
        pc.PostId,
        COUNT(pc.Id) AS CommentCount
    FROM 
        Comments pc
    GROUP BY 
        pc.PostId
),
CombinedResults AS (
    SELECT 
        trp.PostId,
        trp.Title,
        trp.CreationDate,
        trp.ViewCount,
        trp.Score,
        trp.OwnerDisplayName,
        COALESCE(pc.CommentCount, 0) AS CommentCount
    FROM 
        TopRankedPosts trp
    LEFT JOIN 
        PostComments pc ON trp.PostId = pc.PostId
)
SELECT 
    cr.PostId,
    cr.Title,
    cr.CreationDate,
    cr.ViewCount,
    cr.Score,
    cr.OwnerDisplayName,
    cr.CommentCount
FROM 
    CombinedResults cr
ORDER BY 
    cr.Score DESC, cr.ViewCount DESC;
