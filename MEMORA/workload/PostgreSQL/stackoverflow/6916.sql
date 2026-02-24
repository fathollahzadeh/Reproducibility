WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.Score > 0
), 
TopPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        CreationDate,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalResults AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.ViewCount,
        tp.CreationDate,
        tp.OwnerDisplayName,
        COALESCE(pc.CommentCount, 0) AS CommentCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostComments pc ON tp.PostId = pc.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.ViewCount,
    fr.CreationDate,
    fr.OwnerDisplayName,
    fr.CommentCount
FROM 
    FinalResults fr
ORDER BY 
    fr.ViewCount DESC, fr.CommentCount DESC;