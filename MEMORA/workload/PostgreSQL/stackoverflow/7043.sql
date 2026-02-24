
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TagWikis,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        MAX(b.Date) AS MostRecentBadgeDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
ActiveUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.Questions,
        ua.Answers,
        ua.TagWikis,
        ua.TotalUpVotes,
        ua.TotalDownVotes,
        ua.MostRecentBadgeDate,
        RANK() OVER (ORDER BY ua.TotalPosts DESC, ua.TotalUpVotes DESC) AS PostRank
    FROM UserActivity ua
    WHERE ua.TotalPosts > 0
)
SELECT 
    au.DisplayName,
    au.TotalPosts,
    au.Questions,
    au.Answers,
    au.TagWikis,
    au.TotalUpVotes,
    au.TotalDownVotes,
    au.MostRecentBadgeDate,
    CASE 
        WHEN au.PostRank <= 10 THEN 'Top Contributor'
        WHEN au.TotalPosts >= 50 THEN 'Active User'
        ELSE 'Newcomer'
    END AS UserStatus
FROM ActiveUsers au
WHERE au.PostRank <= 50
ORDER BY au.PostRank;
