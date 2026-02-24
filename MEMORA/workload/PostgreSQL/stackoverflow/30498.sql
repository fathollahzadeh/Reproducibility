
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 MONTH' THEN 1 ELSE 0 END) AS RecentPosts,
        AVG(v.VoteTypeId) AS AvgVoteType 
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopCloseReasons AS (
    SELECT 
        ph.Comment AS CloseReason,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.Comment
    ORDER BY 
        CloseCount DESC
    LIMIT 5
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    ua.TotalPosts,
    ua.PositivePosts,
    ua.RecentPosts,
    ub.BadgeCount,
    p.Title AS RecentPostTitle,
    p.CreationDate AS RecentPostDate,
    ROW_NUMBER() OVER (ORDER BY ua.TotalPosts DESC) AS UserRank,
    STRING_AGG(DISTINCT tr.CloseReason, ', ') AS TopCloseReasons
FROM 
    Users u
JOIN 
    UserActivity ua ON u.Id = ua.UserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    RankedPosts p ON u.Id = p.OwnerUserId AND p.rn = 1 
LEFT JOIN 
    TopCloseReasons tr ON 1=1 
WHERE 
    u.Reputation > 100 
GROUP BY 
    u.DisplayName, ua.TotalPosts, ua.PositivePosts, ua.RecentPosts, ub.BadgeCount, p.Title, p.CreationDate
ORDER BY 
    ua.TotalPosts DESC, UserRank;
