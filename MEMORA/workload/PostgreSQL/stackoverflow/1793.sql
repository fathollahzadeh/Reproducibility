
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(p.ViewCount) AS AvgViews
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN cr.Name END) AS CloseReason
    FROM 
        PostHistory ph
        LEFT JOIN CloseReasonTypes cr ON ph.Comment = CAST(cr.Id AS VARCHAR)
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    us.TotalPosts,
    us.PositivePosts,
    us.NegativePosts,
    us.AvgViews,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    cr.CloseReason
FROM 
    Users u
    JOIN UserStatistics us ON u.Id = us.UserId
    LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.PostRank = 1
    LEFT JOIN CloseReasons cr ON rp.PostId = cr.PostId
WHERE 
    u.Reputation > 1000
    AND us.AvgViews > 50
ORDER BY 
    us.Reputation DESC, us.TotalPosts DESC;
