WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),

UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),

PostCommentStats AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount,
        MAX(CreationDate) AS LastCommentDate
    FROM 
        Comments
    GROUP BY 
        PostId
)

SELECT 
    up.DisplayName,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    COALESCE(pcs.CommentCount, 0) AS CommentCount,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    rp.RankScore
FROM 
    Users up
JOIN 
    RankedPosts rp ON up.Id = rp.PostId
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    PostCommentStats pcs ON rp.PostId = pcs.PostId
WHERE 
    rp.RankScore <= 5
ORDER BY 
    rp.Score DESC, 
    up.Reputation DESC;