
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COUNT(v.Id) OVER (PARTITION BY p.Id, v.VoteTypeId) AS UpvoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.RankByScore,
        rp.CommentCount,
        COALESCE(rp.UpvoteCount, 0) AS UpvoteCount,
        p.OwnerUserId
    FROM RankedPosts rp
    JOIN Posts p ON rp.PostId = p.Id
    WHERE rp.RankByScore <= 3
),
UserBadges AS (
    SELECT 
        b.UserId,
        b.Class,
        COUNT(*) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId, b.Class
)
SELECT 
    u.DisplayName,
    COUNT(DISTINCT tp.PostId) AS PostsCount,
    SUM(CASE WHEN ub.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
    SUM(CASE WHEN ub.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
    SUM(CASE WHEN ub.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
FROM Users u
LEFT JOIN TopPosts tp ON u.Id = tp.OwnerUserId
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
WHERE u.Reputation > 1000
GROUP BY u.DisplayName
HAVING COUNT(DISTINCT tp.PostId) > 5
ORDER BY PostsCount DESC, u.DisplayName ASC
LIMIT 10;
