
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM Comments c
    GROUP BY c.PostId
),
UserTopScore AS (
    SELECT 
        u.Id AS UserId,
        SUM(p.Score) AS TotalScore
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
)

SELECT 
    u.DisplayName,
    ub.BadgeCount,
    ub.GoldCount,
    ub.SilverCount,
    ub.BronzeCount,
    COUNT(tp.PostId) AS TopPostsCount,
    SUM(COALESCE(pc.CommentCount, 0)) AS TotalComments,
    ups.TotalScore
FROM Users u
JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN TopPosts tp ON u.Id = (
    SELECT p.OwnerUserId 
    FROM Posts p 
    WHERE p.Id = tp.PostId
) 
LEFT JOIN PostComments pc ON tp.PostId = pc.PostId
LEFT JOIN UserTopScore ups ON u.Id = ups.UserId
WHERE u.Reputation > 1000
GROUP BY u.Id, u.DisplayName, ub.BadgeCount, ub.GoldCount, ub.SilverCount, ub.BronzeCount, ups.TotalScore
ORDER BY ub.BadgeCount DESC, ups.TotalScore DESC
LIMIT 10;
