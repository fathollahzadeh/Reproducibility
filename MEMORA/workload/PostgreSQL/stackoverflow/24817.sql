WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    GROUP BY u.Id, u.DisplayName
),
HighRepUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalUpVotes,
        TotalDownVotes,
        TotalPosts,
        TotalComments,
        RANK() OVER (ORDER BY SUM(TotalUpVotes - TotalDownVotes) DESC) AS RepRank
    FROM UserVoteSummary
    WHERE (TotalUpVotes - TotalDownVotes) > 10
    GROUP BY UserId, DisplayName, TotalUpVotes, TotalDownVotes, TotalPosts, TotalComments
),
RecentPostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN 1 END) AS RecentPostsCount,
        AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate))/60) AS AvgMinutesToActivity,
        MAX(p.Score) AS MaxPostScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserBadgeCount AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    hu.UserId,
    hu.DisplayName,
    hu.TotalUpVotes,
    hu.TotalDownVotes,
    hu.TotalPosts,
    hu.TotalComments,
    r.RecentPostsCount,
    r.AvgMinutesToActivity,
    r.MaxPostScore,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN b.HighestBadgeClass IS NOT NULL THEN 
            CASE 
                WHEN b.HighestBadgeClass = 1 THEN 'Gold' 
                WHEN b.HighestBadgeClass = 2 THEN 'Silver' 
                WHEN b.HighestBadgeClass = 3 THEN 'Bronze'
                ELSE 'None' 
            END
        ELSE 'None' 
    END AS HighestBadge
FROM HighRepUsers hu
LEFT JOIN RecentPostStats r ON hu.UserId = r.OwnerUserId
LEFT JOIN UserBadgeCount b ON hu.UserId = b.UserId
WHERE hu.RepRank <= 10
ORDER BY hu.TotalUpVotes - hu.TotalDownVotes DESC
FETCH FIRST 10 ROWS ONLY;