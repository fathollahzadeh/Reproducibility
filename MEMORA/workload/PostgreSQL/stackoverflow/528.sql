
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
CommentsStatistics AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        AVG(c.Score) AS AverageCommentScore
    FROM Comments c
    GROUP BY c.PostId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    rp.PostId,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    COALESCE(cs.CommentCount, 0) AS CommentCount,
    COALESCE(cs.AverageCommentScore, 0) AS AverageCommentScore,
    CASE 
        WHEN u.Reputation > 1000 THEN 'High Reputation'
        WHEN u.Reputation IS NULL THEN 'No Reputation Data'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM Users u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN RecentPosts rp ON u.Id = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN CommentsStatistics cs ON rp.PostId = cs.PostId
WHERE u.LastAccessDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '90 days'
ORDER BY u.Reputation DESC NULLS LAST, ub.BadgeCount DESC;
