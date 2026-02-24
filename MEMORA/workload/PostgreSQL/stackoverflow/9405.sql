
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
), HighScoringPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Score > 10
)
SELECT 
    hsp.PostId,
    hsp.Title,
    hsp.CreationDate,
    hsp.Score,
    hsp.ViewCount,
    hsp.OwnerDisplayName,
    hsp.CommentCount,
    COALESCE(b.Name, 'None') AS BadgeName
FROM 
    HighScoringPosts hsp
LEFT JOIN 
    Badges b ON hsp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
WHERE 
    hsp.CommentCount > 5
ORDER BY 
    hsp.Score DESC, hsp.ViewCount DESC
FETCH FIRST 50 ROWS ONLY;
