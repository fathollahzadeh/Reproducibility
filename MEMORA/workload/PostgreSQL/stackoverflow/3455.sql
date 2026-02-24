WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownvoteCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
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
    u.DisplayName,
    up.Title,
    up.CreationDate,
    up.Score,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    CASE 
        WHEN up.Rank <= 3 THEN 'Top Post'
        WHEN up.Score > 10 THEN 'Well-Received'
        ELSE 'Moderate'
    END AS PostStatus,
    CASE 
        WHEN up.UpvoteCount IS NULL THEN 0 
        ELSE up.UpvoteCount 
    END AS EffectiveUpvotes,
    COALESCE(NULLIF(up.DownvoteCount, 0), NULL) AS EffectiveDownvotes
FROM 
    RankedPosts up
JOIN 
    Users u ON u.Id = up.OwnerUserId
LEFT JOIN 
    UserBadges ub ON ub.UserId = u.Id
LEFT JOIN 
    PostComments pc ON pc.PostId = up.Id
WHERE 
    up.Rank < 5
ORDER BY 
    up.Score DESC, 
    u.Reputation DESC
LIMIT 100;
