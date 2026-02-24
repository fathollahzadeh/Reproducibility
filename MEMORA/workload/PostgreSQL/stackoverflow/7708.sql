
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS UserPostRank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.OwnerUserId
), UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    up.UserId, 
    up.BadgeCount,
    rp.PostId, 
    rp.Title, 
    rp.Score, 
    rp.ViewCount, 
    rp.CreationDate, 
    rp.CommentCount, 
    rp.VoteCount
FROM 
    UserBadges up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
WHERE 
    up.BadgeCount > 0
    AND rp.UserPostRank <= 3
ORDER BY 
    up.BadgeCount DESC, 
    rp.Score DESC;
