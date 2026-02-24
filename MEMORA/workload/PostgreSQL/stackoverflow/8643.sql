
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        p.OwnerUserId
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate > (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year')
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM Badges b
    WHERE b.Date > (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '3 months')
    GROUP BY b.UserId
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6, 24) 
    GROUP BY ph.PostId
)
SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    r.FeaturedBadgeCount,
    ph.EditCount,
    ph.LastEditDate
FROM RankedPosts rp
LEFT JOIN (
    SELECT 
        rb.UserId,
        rb.BadgeCount AS FeaturedBadgeCount
    FROM RecentBadges rb
    JOIN Users u ON rb.UserId = u.Id
    WHERE rb.BadgeCount > 0
) r ON rp.OwnerUserId = r.UserId
LEFT JOIN PostHistoryAggregated ph ON rp.PostId = ph.PostId
WHERE rp.Rank <= 10
ORDER BY rp.Score DESC, rp.CreationDate DESC;
