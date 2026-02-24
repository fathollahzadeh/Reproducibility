WITH RankedPosts AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.CreationDate, 
           p.Score, 
           p.ViewCount, 
           p.AnswerCount, 
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT rp.PostId, 
           rp.Title, 
           rp.CreationDate, 
           rp.Score, 
           rp.ViewCount, 
           rp.AnswerCount
    FROM RankedPosts rp
    WHERE rp.ScoreRank <= 10
),
UserPostCount AS (
    SELECT p.OwnerUserId, 
           COUNT(p.Id) AS PostCount 
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserBadges AS (
    SELECT b.UserId, 
           COUNT(b.Id) AS BadgeCount,
           MAX(b.Class) AS HighestBadge
    FROM Badges b
    GROUP BY b.UserId
),
Aggregated AS (
    SELECT upc.OwnerUserId,
           upc.PostCount,
           ub.BadgeCount,
           ub.HighestBadge,
           tp.ViewCount AS TopPostViewCount,
           tp.AnswerCount AS TopPostAnswerCount
    FROM UserPostCount upc
    LEFT JOIN UserBadges ub ON upc.OwnerUserId = ub.UserId
    LEFT JOIN TopPosts tp ON upc.OwnerUserId = tp.PostId
)
SELECT u.Id AS UserId,
       u.DisplayName,
       agg.PostCount,
       COALESCE(agg.BadgeCount, 0) AS TotalBadges,
       COALESCE(agg.TopPostViewCount, 0) AS MostViewedPost,
       COALESCE(agg.TopPostAnswerCount, 0) AS MostAnsweredPost
FROM Users u
LEFT JOIN Aggregated agg ON u.Id = agg.OwnerUserId
WHERE u.Reputation > 1000
ORDER BY u.Reputation DESC, agg.PostCount DESC;