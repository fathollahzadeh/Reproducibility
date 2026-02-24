WITH UserBadgeCounts AS (
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
PostsDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(ubc.BadgeCount, 0) AS UserBadgeCount,
        p.OwnerUserId,
        p.Tags
    FROM Posts p
    LEFT JOIN UserBadgeCounts ubc ON p.OwnerUserId = ubc.UserId
),
RankedPosts AS (
    SELECT 
        pd.*,
        ROW_NUMBER() OVER (PARTITION BY pd.OwnerUserId ORDER BY pd.Score DESC, pd.ViewCount DESC) AS PostRank
    FROM PostsDetails pd
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.UserBadgeCount,
    COALESCE(ub.DisplayName, 'Community') AS OwnerDisplayName,
    rp.Tags
FROM RankedPosts rp
LEFT JOIN Users ub ON rp.OwnerUserId = ub.Id
WHERE rp.PostRank <= 3
ORDER BY rp.UserBadgeCount DESC, rp.Score DESC;
