WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    ru.DisplayName,
    ru.Reputation,
    ru.ReputationRank,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount
FROM 
    RankedUsers ru
JOIN 
    TopPosts tp ON ru.UserId = tp.OwnerUserId
LEFT JOIN 
    PostComments pc ON tp.PostId = pc.PostId
LEFT JOIN 
    UserBadges ub ON ru.UserId = ub.UserId
WHERE 
    tp.PostRank <= 3
ORDER BY 
    ru.ReputationRank, tp.Score DESC;
