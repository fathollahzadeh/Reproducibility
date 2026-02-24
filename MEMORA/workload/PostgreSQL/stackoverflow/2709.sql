
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.OwnerUserId, 
        p.Score, 
        p.ViewCount, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
), UserActivities AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
), PostHistoryCounts AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS HistoryCount
    FROM PostHistory ph
    WHERE ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ua.DisplayName,
    ua.TotalUpvotes,
    ua.TotalDownvotes,
    COALESCE(phc.HistoryCount, 0) AS HistoryCount
FROM RecentPosts rp
JOIN Users u ON rp.OwnerUserId = u.Id
JOIN UserActivities ua ON u.Id = ua.UserId
LEFT JOIN PostHistoryCounts phc ON rp.PostId = phc.PostId
WHERE rp.rn = 1
  AND (ua.TotalUpvotes - ua.TotalDownvotes) >= 10
ORDER BY rp.CreationDate DESC
LIMIT 50;
