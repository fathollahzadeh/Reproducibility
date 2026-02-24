WITH RECURSIVE PostHierarchy AS (
    SELECT 
        Id AS PostId, 
        ParentId,
        Title,
        CreationDate,
        0 AS Level
    FROM Posts
    WHERE ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id, 
        p.ParentId,
        p.Title,
        p.CreationDate,
        ph.Level + 1
    FROM Posts p
    INNER JOIN PostHierarchy ph ON p.ParentId = ph.PostId
),
UserStickyPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS StickyPostCount
    FROM Posts p
    WHERE p.ViewCount > 1000
    GROUP BY p.OwnerUserId
),
RecentPosts AS (
    SELECT 
        Id, 
        Title,
        OwnerUserId,
        CreationDate,
        ROW_NUMBER() OVER (PARTITION BY OwnerUserId ORDER BY CreationDate DESC) AS rn
    FROM Posts
    WHERE CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
),
PostViewCount AS (
    SELECT 
        p.Id,
        p.Title,
        COUNT(v.Id) AS VoteCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title
)
SELECT 
    ph.PostId,
    ph.Title AS PostTitle,
    ph.CreationDate AS PostDate,
    u.DisplayName AS OwnerName,
    COALESCE(sp.StickyPostCount, 0) AS OwnerStickyPosts,
    COALESCE(rv.VoteCount, 0) AS RecentPostVotes,
    ph.Level AS HierarchyLevel
FROM PostHierarchy ph
LEFT JOIN Users u ON ph.PostId = u.Id
LEFT JOIN UserStickyPosts sp ON u.Id = sp.OwnerUserId
LEFT JOIN PostViewCount rv ON ph.PostId = rv.Id
WHERE (u.Reputation > 1000 OR sp.StickyPostCount > 0)
    AND ph.Level <= 2
ORDER BY ph.Level, ph.CreationDate DESC;