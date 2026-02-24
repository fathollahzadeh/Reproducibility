WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.Score > 0
),
TopScoringPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        Score,
        ViewCount
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 5
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    p.PostId,
    p.Title,
    p.OwnerDisplayName,
    p.Score,
    p.ViewCount,
    COALESCE(pc.CommentCount, 0) AS CommentCount
FROM 
    TopScoringPosts p
LEFT JOIN 
    PostComments pc ON p.PostId = pc.PostId
ORDER BY 
    p.Score DESC, 
    p.ViewCount DESC;