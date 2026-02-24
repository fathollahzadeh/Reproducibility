
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountySum,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN LATERAL unnest(string_to_array(p.Tags, '><')) AS tag ON TRUE
    LEFT JOIN Tags t ON tag = t.TagName
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
RecentActivity AS (
    SELECT 
        OwnerUserId AS UserId, 
        COUNT(*) AS RecentPostCount 
    FROM Posts 
    WHERE CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    GROUP BY OwnerUserId
)
SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalBountySum,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    pi.Title,
    pi.CreationDate,
    pi.Score,
    pi.CommentCount,
    pi.Tags,
    ra.RecentPostCount,
    CASE 
        WHEN ra.RecentPostCount IS NULL THEN 'Inactive'
        ELSE 'Active'
    END AS ActivityStatus
FROM UserActivity ua
JOIN PostInfo pi ON ua.UserId = pi.PostId
LEFT JOIN RecentActivity ra ON ua.UserId = ra.UserId
WHERE ua.TotalPosts > 0
AND pi.UserPostRank <= 5
ORDER BY ua.TotalUpVotes DESC, pi.Score DESC
LIMIT 100;
