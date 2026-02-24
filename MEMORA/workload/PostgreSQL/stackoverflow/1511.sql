
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        COALESCE(AVG(p.Score), 0) AS AvgScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalBounties,
    us.TotalPosts,
    us.TotalViews,
    us.AvgScore,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate
FROM UserStats us
JOIN RankedPosts rp ON us.TotalPosts > 0 AND us.UserId = (
    SELECT p.OwnerUserId 
    FROM Posts p 
    WHERE p.Id = rp.PostId
)
LEFT JOIN Badges b ON b.UserId = us.UserId AND b.Class = 1
WHERE us.TotalViews > 100 AND rp.PostRank <= 5
ORDER BY us.TotalBounties DESC, us.AvgScore DESC, rp.ViewCount DESC;
