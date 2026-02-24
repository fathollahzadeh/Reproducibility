
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        u.DisplayName AS OwnerDisplayName, 
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        p.PostTypeId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' AND 
        p.ViewCount > 100
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.*, 
        pt.Name AS PostTypeName, 
        ROW_NUMBER() OVER (ORDER BY rp.ViewCount DESC, rp.CommentCount DESC) AS OverallRank
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.PostTypeId = pt.Id
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.CreationDate, 
    tp.ViewCount, 
    tp.CommentCount, 
    tp.OwnerDisplayName, 
    tp.PostTypeName, 
    tp.OverallRank
FROM 
    TopPosts tp
ORDER BY 
    tp.OverallRank;
