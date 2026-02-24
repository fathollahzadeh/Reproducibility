WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate AS PostCreationDate,
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2)  
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.PostCreationDate,
    rp.UserId,
    rp.DisplayName,
    rp.Reputation
FROM 
    RankedPosts rp
WHERE 
    rp.PostRank = 1 
ORDER BY 
    rp.Reputation DESC;