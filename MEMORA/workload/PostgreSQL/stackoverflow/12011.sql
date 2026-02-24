
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    GROUP BY u.Id
),
PostTypeStats AS (
    SELECT 
        pt.Id AS PostTypeId,
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews
    FROM PostTypes pt
    LEFT JOIN Posts p ON pt.Id = p.PostTypeId
    GROUP BY pt.Id, pt.Name
)
SELECT 
    ups.UserId,
    ups.PostCount,
    ups.CommentCount,
    ups.TotalBounty,
    pts.PostTypeId,
    pts.PostTypeName,
    pts.TotalPosts,
    pts.AverageScore,
    pts.TotalViews
FROM UserPostStats ups
CROSS JOIN PostTypeStats pts
ORDER BY ups.UserId, pts.PostTypeId;
