
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Ranking,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, u.DisplayName
),
RecentBadges AS (
    SELECT
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    WHERE b.Date >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY b.UserId
)
SELECT
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rb.BadgeCount
FROM RankedPosts rp
LEFT JOIN RecentBadges rb ON rp.OwnerDisplayName = (SELECT u.DisplayName FROM Users u WHERE u.Id = rb.UserId)
WHERE rp.Ranking <= 10
ORDER BY rp.Score DESC, rp.ViewCount DESC;
