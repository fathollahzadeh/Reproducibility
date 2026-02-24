
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.Views
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        pst.Name AS PostHistoryType
    FROM PostHistory ph
    JOIN PostHistoryTypes pst ON ph.PostHistoryTypeId = pst.Id
    WHERE ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
),
AggregatedData AS (
    SELECT 
        up.UserId,
        up.DisplayName,
        up.Reputation,
        up.Views,
        COALESCE(SUM(rp.Score), 0) AS TotalPostScore,
        COALESCE(SUM(rp.Score) FILTER (WHERE rp.rn = 1), 0) AS MostRecentPostScore,
        COALESCE(MAX(rp.CreationDate), TIMESTAMP '1970-01-01') AS LastPostDate,
        COUNT(rph.PostId) AS RecentEditCount
    FROM UserStats up
    LEFT JOIN RankedPosts rp ON up.UserId = rp.OwnerUserId
    LEFT JOIN RecentPostHistory rph ON rph.UserId = up.UserId
    GROUP BY up.UserId, up.DisplayName, up.Reputation, up.Views
)
SELECT 
    ad.UserId,
    ad.DisplayName,
    ad.Reputation,
    ad.Views,
    ad.TotalPostScore,
    ad.MostRecentPostScore,
    ad.LastPostDate,
    ad.RecentEditCount,
    (ad.Reputation * 0.1 + ad.TotalPostScore * 0.9) AS PerformanceScore
FROM AggregatedData ad
WHERE ad.TotalPostScore > 100
ORDER BY PerformanceScore DESC
LIMIT 10;
