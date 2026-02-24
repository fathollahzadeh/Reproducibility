WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.Views) AS TotalViews,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        AVG(u.Reputation) AS AvgReputation
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalPostViews,
        AVG(p.Score) AS AvgPostScore,
        COUNT(c.Id) AS TotalComments
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.OwnerUserId
),
FinalStats AS (
    SELECT 
        us.UserId,
        us.BadgeCount,
        us.TotalViews,
        us.TotalUpVotes,
        us.TotalDownVotes,
        us.AvgReputation,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.TotalPostViews, 0) AS PostViewCount,
        COALESCE(ps.AvgPostScore, 0) AS AvgPostScore,
        COALESCE(ps.TotalComments, 0) AS TotalComments
    FROM UserStats us
    LEFT JOIN PostStats ps ON us.UserId = ps.OwnerUserId
)
SELECT 
    UserId,
    BadgeCount,
    TotalViews,
    TotalUpVotes,
    TotalDownVotes,
    AvgReputation,
    PostCount,
    PostViewCount,
    AvgPostScore,
    TotalComments
FROM FinalStats
ORDER BY UserId;