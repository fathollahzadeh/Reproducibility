WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY p.Id
),
PostsWithHistory AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (1, 4, 6) THEN ph.CreationDate END) AS LastEdited,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11, 12)) AS ClosureHistory
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT 
    up.UserId,
    SUM(up.Reputation) AS TotalReputation,
    COUNT(DISTINCT ap.PostId) AS ActivePostCount,
    AVG(ap.ViewCount) AS AvgViews,
    COALESCE(SUM(CASE WHEN ph.ClosureHistory > 0 THEN 1 ELSE 0 END), 0) AS ClosureCount,
    STRING_AGG(DISTINCT ap.Title, ', ') AS PostTitles,
    RANK() OVER (ORDER BY SUM(up.Reputation) DESC) AS UserRank
FROM UserReputation up
JOIN ActivePosts ap ON up.UserId = ap.OwnerUserId
LEFT JOIN PostsWithHistory ph ON ap.PostId = ph.PostId
GROUP BY up.UserId
HAVING SUM(up.Reputation) > 1000
ORDER BY TotalReputation DESC
LIMIT 10;