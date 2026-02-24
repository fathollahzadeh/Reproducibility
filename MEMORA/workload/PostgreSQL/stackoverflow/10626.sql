
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBountyAmount,
        COUNT(v.Id) AS TotalVotes,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        MAX(p.CreationDate) AS LastPostDate,
        COUNT(p.Id) AS TotalPosts
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.Score) AS AvgScore
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE p.CreationDate >= '2023-01-01'
    GROUP BY pt.Name
)
SELECT 
    us.DisplayName,
    us.TotalBountyAmount,
    us.TotalVotes,
    us.TotalBadges,
    us.LastPostDate,
    us.TotalPosts,
    ps.PostType,
    ps.PostCount,
    ps.AvgViewCount,
    ps.AvgScore
FROM UserStats us
JOIN PostStats ps ON us.TotalPosts > 0
ORDER BY us.TotalPosts DESC, ps.PostCount DESC;
