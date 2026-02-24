
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount, 
        p.Score, 
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)  
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.ViewCount, 
        rp.Score, 
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    up.DisplayName AS UserName,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
FROM 
    Users up
JOIN 
    Posts p ON up.Id = p.OwnerUserId
JOIN 
    TopPosts tp ON p.Id = tp.PostId
LEFT JOIN 
    Badges b ON up.Id = b.UserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  
GROUP BY 
    up.DisplayName
ORDER BY 
    BadgeCount DESC, TotalBounty DESC
LIMIT 5;
