WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.Score,
        rp.CommentCount,
        rp.VoteCount,
        CASE 
            WHEN rp.Rank = 1 THEN 'Top'
            ELSE 'Regular'
        END AS PostCategory
    FROM 
        RankedPosts rp
)
SELECT 
    u.DisplayName AS UserName,
    tp.Title,
    tp.Score,
    tp.CommentCount,
    tp.VoteCount,
    tp.PostCategory,
    COALESCE(b.Name, 'No Badge') AS BadgeName
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Class = 1
WHERE 
    tp.VoteCount > 5
ORDER BY 
    tp.Score DESC, tp.CreationDate ASC
LIMIT 10;