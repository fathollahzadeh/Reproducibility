
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate, p.Score, p.ViewCount, pt.Name
),
TopPosts AS (
    SELECT 
        rp.*, 
        pt.Name AS PostTypeName
    FROM 
        RankedPosts rp
    INNER JOIN 
        PostTypes pt ON rp.Rank <= 5
)
SELECT 
    t.PostId,
    t.Title,
    t.OwnerDisplayName,
    t.CreationDate,
    t.Score,
    t.ViewCount,
    t.CommentCount,
    t.PostTypeName
FROM 
    TopPosts t
ORDER BY 
    t.PostTypeName, t.Score DESC;
