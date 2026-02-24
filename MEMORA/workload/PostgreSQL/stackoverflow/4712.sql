
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        COUNT(DISTINCT CASE WHEN b.Id IS NOT NULL THEN b.Id END) AS BadgeCount,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS PostRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank,
        p.OwnerUserId
    FROM Posts p
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        ARRAY_AGG(DISTINCT c.Name) AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes c ON CAST(ph.Comment AS INTEGER) = c.Id
    WHERE ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY ph.PostId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostCount,
    ua.TotalViews,
    ua.TotalScore,
    ua.BadgeCount,
    rp.PostId,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    cp.CloseCount,
    COALESCE(cp.CloseReasons, ARRAY[]::VARCHAR[]) AS CloseReasons,
    ua.PostRank
FROM UserActivity ua
LEFT JOIN RecentPosts rp ON ua.UserId = rp.OwnerUserId AND rp.RecentPostRank = 1
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
ORDER BY ua.TotalScore DESC, ua.PostCount DESC;
