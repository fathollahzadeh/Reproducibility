
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)  
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.*,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(u.Reputation, 0) AS OwnerReputation
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.ScoreRank <= 10
)
SELECT 
    p.Title,
    p.Score,
    p.ViewCount,
    p.CreationDate,
    p.OwnerDisplayName,
    p.OwnerReputation,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    STRING_AGG(b.Name, ', ') AS Badges
FROM 
    TopPosts p
LEFT JOIN 
    Badges b ON p.OwnerUserId = b.UserId
GROUP BY 
    p.Title, p.Score, p.ViewCount, p.CreationDate, p.OwnerDisplayName, p.OwnerReputation
ORDER BY 
    p.Score DESC, p.CreationDate DESC
LIMIT 100;
