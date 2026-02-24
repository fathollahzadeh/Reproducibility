
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2020-01-01' 
)

SELECT 
    rp.PostId, 
    rp.Title, 
    rp.Score, 
    rp.ViewCount, 
    rp.AnswerCount, 
    rp.CommentCount, 
    rp.OwnerDisplayName
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 10  
ORDER BY 
    rp.Score DESC;
