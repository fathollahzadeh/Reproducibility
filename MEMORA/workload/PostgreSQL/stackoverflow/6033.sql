
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
TopPosts AS (
    SELECT * FROM RankedPosts
    WHERE Rank <= 5
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
UserRankWithBadges AS (
    SELECT 
        p.OwnerUserId,
        COUNT(tp.PostId) AS TopPostCount,
        ub.BadgeCount
    FROM 
        TopPosts tp
    JOIN 
        Posts p ON tp.PostId = p.Id
    JOIN 
        UserBadges ub ON p.OwnerUserId = ub.UserId
    GROUP BY 
        p.OwnerUserId, ub.BadgeCount
)
SELECT 
    u.DisplayName,
    ur.TopPostCount,
    ur.BadgeCount
FROM 
    Users u
JOIN 
    UserRankWithBadges ur ON u.Id = ur.OwnerUserId
ORDER BY 
    ur.TopPostCount DESC, ur.BadgeCount DESC
FETCH FIRST 10 ROWS ONLY;
