WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM Posts p
    WHERE p.PostTypeId = 1 
      AND p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM Comments c
    GROUP BY c.PostId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rb.GoldBadges,
    rb.SilverBadges,
    rb.BronzeBadges,
    pc.CommentCount,
    pc.LastCommentDate,
    CASE 
        WHEN pc.LastCommentDate IS NULL THEN 'No comments yet'
        ELSE 'Comments available'
    END AS CommentStatus,
    CASE 
        WHEN rp.RankByViews = 1 THEN 'Most Viewed'
        WHEN rp.RankByScore = 1 THEN 'Top Scoring'
        ELSE 'Regular Post'
    END AS PostRankStatus
FROM RankedPosts rp
LEFT JOIN UserBadges rb ON rp.OwnerUserId = rb.UserId
LEFT JOIN PostComments pc ON rp.Id = pc.PostId
WHERE rp.RankByViews <= 5 AND rp.RankByScore <= 5
ORDER BY rp.ViewCount DESC, rp.Score DESC;