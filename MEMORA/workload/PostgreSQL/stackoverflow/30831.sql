WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL 

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(b.Class) AS BadgeCount,
        MAX(p.CreationDate) AS LastActive,
        DENSE_RANK() OVER (PARTITION BY u.Id ORDER BY MAX(p.CreationDate) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
MostPopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    WHERE 
        p.ViewCount IS NOT NULL
),
ActiveUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostCount,
        ua.BadgeCount
    FROM 
        UserActivity ua
    WHERE 
        ua.LastActive >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' AND 
        ua.PostCount > 0
)
SELECT 
    ph.Title AS PostTitle,
    ph.Level AS PostLevel,
    up.UserId,
    up.DisplayName AS UserName,
    COALESCE(mp.ViewCount, 0) AS Popularity,
    CASE 
        WHEN up.BadgeCount > 5 THEN 'Active Contributor'
        ELSE 'Regular Member'
    END AS UserStatus
FROM 
    PostHierarchy ph
LEFT JOIN 
    ActiveUsers up ON ph.PostId = up.UserId
LEFT JOIN 
    MostPopularPosts mp ON ph.PostId = mp.Id
WHERE 
    (up.UserId IS NULL OR up.BadgeCount IS NOT NULL) AND
    EXISTS (
        SELECT 1
        FROM Comments c
        WHERE c.PostId = ph.PostId AND c.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '7 days'
    )
ORDER BY 
    ph.Level, UserStatus DESC, Popularity DESC
LIMIT 50;