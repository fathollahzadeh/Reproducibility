WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.Score > 0 AND 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '6 months'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(b.Class, 0) AS BadgeClass
    FROM 
        Users u
    LEFT JOIN 
        (SELECT 
            UserId, 
            MAX(Class) AS Class 
        FROM 
            Badges 
        GROUP BY 
            UserId) b ON u.Id = b.UserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        ur.Reputation,
        ur.BadgeClass
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE 
        rp.Rank = 1
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.Reputation,
    CASE 
        WHEN tp.BadgeClass = 1 THEN 'Gold'
        WHEN tp.BadgeClass = 2 THEN 'Silver'
        WHEN tp.BadgeClass = 3 THEN 'Bronze'
        ELSE 'No Badge'
    END AS BadgeStatus,
    (SELECT 
        COUNT(*) 
     FROM 
        Comments c 
     WHERE 
        c.PostId = tp.PostId) AS CommentCount,
    COALESCE((
        SELECT 
            MAX(OH.CreationDate) 
        FROM 
            PostHistory OH 
        WHERE 
            OH.PostId = tp.PostId AND 
            OH.PostHistoryTypeId IN (4, 5, 6)), 
        tp.CreationDate) AS LastEditDate
FROM 
    TopPosts tp
WHERE 
    tp.Reputation > (SELECT AVG(Reputation) FROM Users) 
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;