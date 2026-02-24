
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostComments AS (
    SELECT 
        c.PostId, 
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LatestCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    rp.Score,
    ur.Reputation,
    ur.BadgeCount,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges,
    pc.CommentCount,
    pc.LatestCommentDate,
    CASE 
        WHEN rp.Score > 50 THEN 'Highly Rated'
        WHEN rp.Score > 20 THEN 'Moderately Rated'
        ELSE 'Low Rated' 
    END AS RatingCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    UserReputation ur ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ur.UserId)
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    rp.PostRank <= 10
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
