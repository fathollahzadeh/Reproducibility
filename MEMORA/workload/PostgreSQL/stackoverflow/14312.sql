
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalBounty,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    ROUND(COALESCE(ua.TotalUpVotes, 0) * 1.0 / NULLIF(ua.TotalPosts, 0), 2) AS UpVoteRate,
    ROUND(COALESCE(ua.TotalDownVotes, 0) * 1.0 / NULLIF(ua.TotalPosts, 0), 2) AS DownVoteRate
FROM UserActivity ua
ORDER BY ua.TotalPosts DESC
LIMIT 100;
