
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON u.Id = v.UserId AND v.VoteTypeId = 9
    GROUP BY u.Id, u.DisplayName
)

SELECT 
    us.DisplayName,
    us.TotalBounties,
    us.TotalViews,
    us.TotalPosts,
    us.AverageScore,
    COUNT(DISTINCT rp.Id) AS TopPostsCount,
    MAX(rp.Score) AS MaxScore,
    MIN(rp.Score) AS MinScore,
    STRING_AGG(rp.Title, '; ') AS TopPostTitles
FROM UserStats us
LEFT JOIN RankedPosts rp ON us.UserId = rp.OwnerUserId
WHERE us.TotalPosts > 0
GROUP BY us.DisplayName, us.TotalBounties, us.TotalViews, us.TotalPosts, us.AverageScore
HAVING AVG(us.AverageScore) > 0 AND COUNT(rp.Id) > 2
ORDER BY us.TotalBounties DESC, us.TotalViews DESC;
