
WITH UserEngagement AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        AVG(EXTRACT(EPOCH FROM (COALESCE(c.CreationDate, TIMESTAMP '2024-10-01 12:34:56') - p.CreationDate))) AS AvgResponseTime
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE u.Reputation > 100  
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditHistory,
        p.CreationDate,
        EXTRACT(EPOCH FROM (COALESCE(p.ClosedDate, TIMESTAMP '2024-10-01 12:34:56') - p.CreationDate)) AS ActiveDuration
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5)  
    WHERE p.Score > 0
    GROUP BY p.Id, p.OwnerUserId, p.CreationDate, p.ClosedDate
),
ClosedPosts AS (
    SELECT
        p.Id AS PostId,
        COUNT(ph.Id) AS CloseHistoryCount,
        MIN(ph.CreationDate) AS FirstCloseDate
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11)  
    WHERE p.ClosedDate IS NOT NULL
    GROUP BY p.Id
)
SELECT
    ue.UserId,
    ue.DisplayName,
    ue.TotalBounty,
    ue.TotalPosts,
    ue.AvgResponseTime,
    ps.PostId,
    ps.CommentCount,
    ps.EditHistory,
    ps.ActiveDuration,
    cp.CloseHistoryCount,
    cp.FirstCloseDate
FROM UserEngagement ue
LEFT JOIN PostStats ps ON ue.UserId = ps.OwnerUserId
LEFT JOIN ClosedPosts cp ON ps.PostId = cp.PostId
WHERE (cp.CloseHistoryCount IS NULL OR cp.CloseHistoryCount <= 3)
AND (ue.TotalPosts > 5 OR (ue.TotalBounty IS NULL AND ue.AvgResponseTime < 86400))  
ORDER BY ue.TotalBounty DESC, ue.AvgResponseTime ASC
LIMIT 50;
