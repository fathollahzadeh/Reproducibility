
WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        p.CreationDate, 
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND p.CreationDate >= DATE '2023-01-01' 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        Id, 
        Title, 
        OwnerDisplayName, 
        Score, 
        ViewCount, 
        CommentCount 
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    trp.Title, 
    trp.OwnerDisplayName, 
    trp.Score, 
    trp.ViewCount, 
    trp.CommentCount, 
    ph.CreationDate, 
    pht.Name AS PostHistoryTypeName
FROM 
    TopRankedPosts trp
JOIN 
    PostHistory ph ON trp.Id = ph.PostId
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    ph.CreationDate >= DATE '2023-01-01' 
ORDER BY 
    trp.Score DESC, trp.ViewCount DESC;
