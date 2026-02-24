WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        AVG(p.Score) AS AvgPostScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
RecentActivity AS (
    SELECT 
        UserId,
        COUNT(*) AS RecentActions,
        MAX(CreationDate) AS LastActionDate
    FROM PostHistory
    WHERE CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY UserId
),
QualifiedUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalUpVotes,
        us.TotalDownVotes,
        us.TotalPosts,
        us.AvgPostScore,
        us.LastPostDate,
        ra.RecentActions,
        ra.LastActionDate
    FROM UserStats us
    LEFT JOIN RecentActivity ra ON us.UserId = ra.UserId
    WHERE us.TotalPosts > 5 
      AND (us.TotalUpVotes - us.TotalDownVotes) > 10 
)
SELECT 
    q.DisplayName,
    q.TotalPosts,
    q.AvgPostScore,
    CASE 
        WHEN q.LastActionDate IS NULL THEN 'No Recent Activity'
        WHEN q.LastActionDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '14 days' THEN 'Inactive'
        ELSE 'Active'
    END AS ActivityStatus,
    STRING_AGG(DISTINCT p.Tags, ', ') AS TagsUsed
FROM QualifiedUsers q
LEFT JOIN Posts p ON q.UserId = p.OwnerUserId
GROUP BY q.UserId, q.DisplayName, q.TotalPosts, q.AvgPostScore, q.LastActionDate
ORDER BY q.TotalPosts DESC, q.AvgPostScore DESC
LIMIT 10;