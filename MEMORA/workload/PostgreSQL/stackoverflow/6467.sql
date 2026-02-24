
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        COALESCE(p.Score, 0) AS Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        RANK() OVER (ORDER BY COALESCE(p.Score, 0) DESC, COALESCE(p.ViewCount, 0) DESC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days') AND p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score
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
), UserTopPost AS (
    SELECT 
        p.OwnerUserId,
        MAX(p.ViewCount) AS MaxViewCount
    FROM 
        Posts p
    WHERE 
        p.OwnerUserId IS NOT NULL
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    rp.VoteCount,
    ub.BadgeCount,
    ut.MaxViewCount
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.PostId = ub.UserId
LEFT JOIN 
    UserTopPost ut ON rp.PostId = ut.OwnerUserId
WHERE 
    rp.RankScore <= 10
ORDER BY 
    rp.RankScore;
