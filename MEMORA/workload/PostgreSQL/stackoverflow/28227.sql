
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        U.DisplayName AS OwnerDisplayName,
        p.Score,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON U.Id = b.UserId
    WHERE 
        p.PostTypeId = 1 AND  
        p.CreationDate > DATE '2024-10-01' - INTERVAL '1 year' 
    GROUP BY 
        p.Id, U.DisplayName, p.Title, p.Body, p.Score, p.CreationDate
),

TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        OwnerDisplayName,
        Score,
        CreationDate,
        CommentCount,
        BadgeCount
    FROM 
        RankedPosts
    WHERE 
        Rank = 1 
)

SELECT 
    tp.OwnerDisplayName,
    tp.Title,
    tp.Body,
    tp.Score,
    tp.CommentCount,
    tp.BadgeCount,
    CASE 
        WHEN tp.Score > 10 THEN 'Hot'
        WHEN tp.Score > 0 THEN 'Popular'
        ELSE 'New'
    END AS PostCategory,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    unnest(string_to_array(substring(tp.Body, 2, length(tp.Body)-2), '> <')) AS tag ON tag LIKE 'tag-%'  
LEFT JOIN 
    Tags t ON LOWER(t.TagName) = LOWER(tag)  
GROUP BY 
    tp.OwnerDisplayName, tp.Title, tp.Body, tp.Score, tp.CommentCount, tp.BadgeCount
ORDER BY 
    tp.Score DESC,
    tp.CommentCount DESC;
