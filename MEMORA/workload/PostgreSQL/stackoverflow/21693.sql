WITH RecentUserActivities AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId 
    WHERE u.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY u.Id
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AvgScore,
        MAX(p.ViewCount) AS MaxViews,
        MIN(p.CreationDate) AS FirstPostDate
    FROM Posts p
    GROUP BY p.OwnerUserId
),
BadgesForUsers AS (
    SELECT
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeList,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
),
CloseReasonSummary AS (
    SELECT
        ph.UserId,
        COUNT(ph.Id) AS CloseCount,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasonNames
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE ph.PostHistoryTypeId = 10  
    GROUP BY ph.UserId
)
SELECT 
    u.DisplayName,
    ru.VoteCount,
    ru.UpVotes,
    ru.DownVotes,
    ps.TotalPosts,
    ps.AvgScore,
    ps.MaxViews,
    ps.FirstPostDate,
    b.BadgeList,
    b.BadgeCount,
    cs.CloseCount,
    cs.CloseReasonNames
FROM Users u
LEFT JOIN RecentUserActivities ru ON u.Id = ru.UserId
LEFT JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
LEFT JOIN BadgesForUsers b ON u.Id = b.UserId
LEFT JOIN CloseReasonSummary cs ON u.Id = cs.UserId
WHERE u.Reputation > 1000 
    AND (ru.VoteCount > 10 OR ps.TotalPosts > 5)
ORDER BY 
    COALESCE(ru.UpVotes, 0) DESC, 
    COALESCE(ps.MaxViews, 0) DESC;