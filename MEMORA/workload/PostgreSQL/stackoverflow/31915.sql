WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
    UNION ALL
    SELECT 
        a.Id AS PostId,
        a.Title,
        a.ParentId,
        ph.Level + 1
    FROM 
        Posts a
    INNER JOIN 
        PostHierarchy ph ON a.ParentId = ph.PostId
    WHERE 
        a.PostTypeId = 2  
),
GroupedVotes AS (
    SELECT 
        v.PostId,
        vt.Name AS VoteType,
        COUNT(*) AS VoteCount
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.PostId, vt.Name
),
BadgeStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(gv.VoteCount, 0) AS TotalVotes,
        COALESCE(b.BadgeCount, 0) AS UserBadgeCount,
        COALESCE(b.LastBadgeDate, '1900-01-01') AS LastBadgeDate,
        ph.Level AS HierarchyLevel
    FROM Posts p
    LEFT JOIN GroupedVotes gv ON p.Id = gv.PostId
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN BadgeStats b ON u.Id = b.UserId
    LEFT JOIN PostHierarchy ph ON ph.PostId = p.Id
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.TotalVotes,
    ps.UserBadgeCount,
    ps.LastBadgeDate,
    ps.HierarchyLevel
FROM 
    PostStats ps
WHERE 
    ps.TotalVotes > 0 
    AND ps.UserBadgeCount > 1
ORDER BY 
    ps.TotalVotes DESC, 
    ps.HierarchyLevel ASC
LIMIT 10;