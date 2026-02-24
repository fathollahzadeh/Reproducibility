
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostHistorySummary AS (
    SELECT 
        ph.UserId, 
        COUNT(ph.Id) AS EditCount,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6)
    GROUP BY ph.UserId
)
SELECT 
    u.DisplayName,
    COALESCE(us.PostCount, 0) AS TotalPosts,
    COALESCE(us.TotalScore, 0) AS AggregateScore,
    COALESCE(phs.EditCount, 0) AS TotalEdits,
    phs.FirstEditDate,
    phs.LastEditDate,
    rp.Title AS LatestPostTitle
FROM Users u
LEFT JOIN UserStats us ON u.Id = us.UserId
LEFT JOIN PostHistorySummary phs ON u.Id = phs.UserId
LEFT JOIN RankedPosts rp ON u.Id = rp.PostId
WHERE u.Reputation > 1000
  AND (phs.LastEditDate IS NULL OR phs.LastEditDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
ORDER BY AggregateScore DESC, TotalPosts DESC
LIMIT 100;
