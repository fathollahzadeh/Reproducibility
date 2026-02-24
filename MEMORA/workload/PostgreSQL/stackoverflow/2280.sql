
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(p.ViewCount) AS AvgViewCount,
        MAX(p.CreationDate) AS MostRecentPost,
        MIN(p.CreationDate) AS FirstPost
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 100
    GROUP BY u.Id, u.DisplayName
),

RecentChanges AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM PostHistory ph
    WHERE ph.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
)

SELECT 
    ps.UserId,
    ps.DisplayName,
    ps.TotalPosts,
    ps.PositivePosts,
    ps.NegativePosts,
    ps.AvgViewCount,
    rc.CreationDate AS LastChangeDate,
    rc.PostHistoryTypeId,
    CASE 
        WHEN rc.PostHistoryTypeId IN (10, 11) THEN 'Status Changed'
        ELSE 'No Recent Status Change'
    END AS ChangeStatus,
    COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ps.UserId)), 0) AS TotalComments
FROM UserPostStats ps
LEFT JOIN RecentChanges rc ON ps.TotalPosts > 0 AND rc.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ps.UserId)
WHERE rc.rn = 1
ORDER BY ps.TotalPosts DESC, ps.AvgViewCount DESC;
