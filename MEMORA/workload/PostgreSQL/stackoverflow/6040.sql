WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score, 
        u.DisplayName AS OwnerDisplayName, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
TopPosts AS (
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
),
PostDetails AS (
    SELECT 
        tp.PostId, 
        tp.Title, 
        tp.CreationDate, 
        tp.ViewCount, 
        tp.Score, 
        tp.OwnerDisplayName, 
        COALESCE(pc.CommentCount, 0) AS CommentCount
    FROM 
        TopPosts tp 
    LEFT JOIN 
        PostComments pc ON tp.PostId = pc.PostId
)
SELECT 
    pd.Title, 
    pd.CreationDate, 
    pd.ViewCount, 
    pd.Score, 
    pd.OwnerDisplayName, 
    pd.CommentCount, 
    pt.Name AS PostTypeName
FROM 
    PostDetails pd
JOIN 
    PostTypes pt ON pd.PostId IN (SELECT Id FROM Posts WHERE PostTypeId = pt.Id)
ORDER BY 
    pd.Score DESC, 
    pd.ViewCount DESC;