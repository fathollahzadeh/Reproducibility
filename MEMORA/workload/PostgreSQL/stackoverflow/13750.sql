WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(COALESCE(u.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(u.DownVotes, 0)) AS TotalDownVotes,
        SUM(u.Reputation) AS TotalReputation
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    GROUP BY p.OwnerUserId
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostCount,
    ua.CommentCount,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    ua.TotalReputation,
    ps.TotalPosts,
    ps.TotalScore,
    ps.TotalViews
FROM UserActivity ua
LEFT JOIN PostStats ps ON ua.UserId = ps.OwnerUserId
ORDER BY ua.TotalReputation DESC, ua.PostCount DESC;