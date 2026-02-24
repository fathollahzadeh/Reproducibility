
WITH RankedPosts AS (
    SELECT 
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 YEAR'
    GROUP BY 
        p.Title, p.CreationDate, p.Score, u.DisplayName, p.PostTypeId
),
TopPosts AS (
    SELECT 
        Title, 
        CreationDate, 
        OwnerDisplayName, 
        Score 
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 10
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.Score,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    Posts p ON tp.Title = p.Title
LEFT JOIN 
    Tags t ON p.Id = t.ExcerptPostId
GROUP BY 
    tp.Title, tp.CreationDate, tp.OwnerDisplayName, tp.Score
ORDER BY 
    tp.Score DESC;
