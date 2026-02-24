
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),

UserRanking AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 3 WHEN b.Class = 2 THEN 2 ELSE 1 END) AS BadgeCount,
        RANK() OVER (ORDER BY SUM(CASE WHEN b.Class = 1 THEN 3 WHEN b.Class = 2 THEN 2 ELSE 1 END) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    ur.UserId,
    ur.DisplayName AS UserDisplayName,
    ur.BadgeCount,
    CASE 
        WHEN rp.PostRank <= 3 THEN 'Top Post'
        WHEN rp.PostRank BETWEEN 4 AND 10 THEN 'Popular Post'
        ELSE 'Regular Post'
    END AS PostCategory,
    CASE 
        WHEN ur.BadgeCount > 10 THEN 'Highly Accomplished'
        ELSE 'Novice Contributor'
    END AS UserStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    Posts p ON p.Id = rp.PostId
LEFT JOIN 
    Users u ON u.Id = p.OwnerUserId
LEFT JOIN 
    UserRanking ur ON ur.UserId = u.Id
WHERE 
    (u.Reputation > 500 OR rp.ViewCount > 1000)
    AND (p.AcceptedAnswerId IS NOT NULL OR rp.CommentCount > 5)
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 50;
