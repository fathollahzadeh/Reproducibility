WITH RECURSIVE UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        b.Name AS BadgeName,
        b.Class,
        b.Date,
        RANK() OVER (PARTITION BY u.Id ORDER BY b.Date DESC) AS BadgeRank
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Class <= 2 
),
RecentPosts AS (
    SELECT 
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
),
ClosedPosts AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.CreationDate,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.UserId, ph.PostId, ph.CreationDate
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(rp.PostCount, 0) AS RecentPostCount,
        COALESCE(cp.CloseCount, 0) AS ClosedPostCount,
        COUNT(DISTINCT ub.BadgeName) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            OwnerUserId,
            COUNT(*) AS PostCount
        FROM 
            RecentPosts
        WHERE 
            RecentPostRank = 1
        GROUP BY 
            OwnerUserId
    ) rp ON u.Id = rp.OwnerUserId
    LEFT JOIN ClosedPosts cp ON u.Id = cp.UserId
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    GROUP BY 
        u.Id, u.DisplayName, rp.PostCount, cp.CloseCount
)
SELECT 
    ue.UserId,
    ue.DisplayName,
    ue.RecentPostCount,
    ue.ClosedPostCount,
    ue.BadgeCount,
    RANK() OVER (ORDER BY ue.RecentPostCount DESC, ue.ClosedPostCount) AS EngagementRank
FROM 
    UserEngagement ue
WHERE 
    ue.RecentPostCount > 0 
ORDER BY 
    EngagementRank, ue.DisplayName;