WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Tags,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND  
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'  
)

SELECT 
    rp.OwnerDisplayName,
    rp.Title,
    rp.CreationDate,
    rp.Tags,
    rp.ViewCount,
    rp.Score,
    CASE 
        WHEN rp.AnswerCount > 0 THEN CAST(rp.Score AS FLOAT) / NULLIF(rp.AnswerCount, 0)
        ELSE NULL 
    END AS ScorePerAnswer,
    COUNT(c.Id) AS CommentCount
FROM 
    RankedPosts rp
LEFT JOIN 
    Comments c ON rp.PostId = c.PostId
WHERE 
    rp.Rank <= 3  
GROUP BY 
    rp.OwnerDisplayName, rp.Title, rp.CreationDate, rp.Tags, rp.ViewCount, rp.Score, rp.AnswerCount
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;