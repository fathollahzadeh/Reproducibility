WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        SUM(b.Class) AS TotalBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS CloseReason
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY ph.PostId
),
AllData AS (
    SELECT 
        us.UserId,
        us.TotalPosts,
        us.PositivePosts,
        us.AvgScore,
        us.TotalBadges,
        pa.CommentCount,
        pa.VoteCount,
        pa.LastEditDate,
        cp.ClosedDate,
        cp.CloseReason
    FROM UserStats us
    LEFT JOIN PostActivity pa ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = pa.PostId LIMIT 1)
    LEFT JOIN ClosedPosts cp ON pa.PostId = cp.PostId
)
SELECT 
    UserId,
    TotalPosts,
    PositivePosts,
    AvgScore,
    TotalBadges,
    COALESCE(CommentCount, 0) AS TotalComments,
    COALESCE(VoteCount, 0) AS TotalVotes,
    LastEditDate,
    CASE 
        WHEN ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    COALESCE(CloseReason, 'N/A') AS CloseReason
FROM AllData
WHERE TotalPosts > 10 
  AND (AvgScore BETWEEN 0 AND 5 OR PositivePosts > 5)
ORDER BY AvgScore DESC, TotalPosts DESC;