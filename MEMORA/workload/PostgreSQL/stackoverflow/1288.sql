
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.OwnerUserId
)
SELECT 
    u.DisplayName,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.CommentCount,
    COALESCE(b.Name, 'No Badge') AS BadgeName
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.PostId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Class = 1
WHERE 
    rp.PostRank = 1
    AND EXISTS (
        SELECT 1
        FROM Votes v
        WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2
    )
ORDER BY 
    rp.ViewCount DESC
FETCH FIRST 10 ROWS ONLY;
