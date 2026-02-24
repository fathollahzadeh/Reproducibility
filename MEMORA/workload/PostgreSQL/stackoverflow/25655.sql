WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2023-01-01' 
        AND p.ViewCount > 100                 
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.Score,
    rp.OwnerDisplayName,
    rp.OwnerReputation
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5  
ORDER BY 
    rp.Tags, rp.Score DESC;