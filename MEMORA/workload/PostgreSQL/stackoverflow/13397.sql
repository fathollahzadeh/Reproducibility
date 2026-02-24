WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(c.Id, 0)) AS TotalComments
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.Reputation
),
PostTypesStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM PostTypes pt
    LEFT JOIN Posts p ON pt.Id = p.PostTypeId
    GROUP BY pt.Name
)
SELECT 
    us.UserId,
    us.Reputation,
    us.PostCount,
    us.TotalViews,
    us.TotalComments,
    pts.PostType,
    pts.PostCount AS PostTypeCount,
    pts.TotalViews AS PostTypeTotalViews,
    pts.AverageScore
FROM UserStats us
CROSS JOIN PostTypesStats pts
ORDER BY us.Reputation DESC, pts.PostType;