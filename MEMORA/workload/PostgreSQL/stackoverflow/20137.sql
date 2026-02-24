WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        BadgeCount, 
        LastBadgeDate,
        RANK() OVER (ORDER BY BadgeCount DESC) AS UserRank
    FROM 
        UserBadges
    WHERE 
        BadgeCount > 5
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        AVG(p.ViewCount) AS AverageViews,
        MAX(p.LastActivityDate) AS LastActivity
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        p.TotalPosts,
        p.QuestionCount,
        p.AverageViews,
        COALESCE(p.LastActivity, u.CreationDate) AS LastActivityDate,
        b.BadgeCount AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        PostStats p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        UserBadges b ON u.Id = b.UserId
    WHERE 
        COALESCE(p.TotalPosts, 0) > 0 OR b.BadgeCount > 0
),
HighlyActiveUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.BadgeCount,
        ua.LastActivityDate,
        DENSE_RANK() OVER (ORDER BY ua.LastActivityDate DESC) AS ActivityRank
    FROM 
        UserActivity ua
    WHERE 
        ua.AverageViews > 15
),
ClosedPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(h.Id) AS ClosedCount
    FROM 
        Posts p
    INNER JOIN 
        PostHistory h ON p.Id = h.PostId 
                      AND h.PostHistoryTypeId = 10 
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    ah.UserId,
    ah.DisplayName,
    ah.BadgeCount,
    ah.LastActivityDate,
    COALESCE(cp.ClosedCount, 0) AS ClosedPostsCount,
    CASE 
        WHEN ah.ActivityRank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorType
FROM 
    HighlyActiveUsers ah
LEFT JOIN 
    ClosedPosts cp ON ah.UserId = cp.OwnerUserId
WHERE 
    ah.LastActivityDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
ORDER BY 
    ah.BadgeCount DESC, ah.LastActivityDate DESC
LIMIT 20;