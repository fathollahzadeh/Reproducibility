WITH UserBadges AS (
    SELECT u.Id AS UserId, COUNT(b.Id) AS BadgeCount, SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PopularTags AS (
    SELECT TagName, COUNT(p.Id) AS PostCount
    FROM Tags t
    JOIN Posts p ON t.Id = p.Id
    GROUP BY t.TagName
    ORDER BY PostCount DESC
    LIMIT 10
),
TopPosts AS (
    SELECT p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName AS Author,
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Ranking
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    ORDER BY p.Score DESC
    LIMIT 20
)
SELECT ub.UserId, ub.BadgeCount, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges,
       pt.TagName, pt.PostCount, tp.Title, tp.Score, tp.ViewCount, tp.Author
FROM UserBadges ub
CROSS JOIN PopularTags pt
JOIN TopPosts tp ON tp.Ranking <= 5
WHERE ub.BadgeCount > 0
ORDER BY ub.BadgeCount DESC, pt.PostCount DESC, tp.Score DESC;