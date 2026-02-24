WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        COALESCE(p.Score, 0) AS Score, 
        COALESCE(p.ViewCount, 0) AS ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (ORDER BY COALESCE(p.Score, 0) DESC, COALESCE(p.ViewCount, 0) DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= '2023-01-01 00:00:00'  
),
UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000  
    GROUP BY 
        u.Id
),
PostComments AS (
    SELECT 
        c.PostId, 
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.CreationDate, 
    rp.Score, 
    rp.ViewCount, 
    u.DisplayName AS OwnerDisplayName,
    ub.BadgeCount,
    pc.CommentCount
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    rp.Rank <= 10  
ORDER BY 
    rp.Rank, rp.Score DESC;