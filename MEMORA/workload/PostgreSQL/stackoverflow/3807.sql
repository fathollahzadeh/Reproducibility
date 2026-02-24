WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserPostStats AS (
    SELECT
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePostCount,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePostCount,
        AVG(p.ViewCount) AS AvgViewCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstCloseDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 
    GROUP BY ph.PostId
)
SELECT 
    up.UserId,
    up.PostCount,
    up.PositivePostCount,
    up.NegativePostCount,
    up.AvgViewCount,
    cp.FirstCloseDate,
    rp.Title,
    rp.CreationDate AS LatestPostDate,
    rp.Score,
    rp.ViewCount
FROM UserPostStats up
LEFT JOIN ClosedPosts cp ON up.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = cp.PostId)
LEFT JOIN RankedPosts rp ON up.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
WHERE up.PostCount > 0
ORDER BY up.PostCount DESC, up.PositivePostCount DESC NULLS LAST
LIMIT 100;