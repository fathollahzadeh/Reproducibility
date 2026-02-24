WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId, 
        p.Title,
        p.PostTypeId,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        1 AS Level
    FROM 
        Posts p 
    WHERE 
        p.PostTypeId = 1  
    UNION ALL
    SELECT 
        p2.Id AS PostId,
        p2.Title,
        p2.PostTypeId,
        COALESCE(p2.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        p2.CreationDate,
        p2.ViewCount,
        p2.Score,
        ph.Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        PostHierarchy ph ON ph.PostId = p2.ParentId
), 
PostScores AS (
    SELECT 
        ph.PostId,
        ph.Title,
        ph.CreationDate,
        ph.ViewCount,
        ph.Score,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHierarchy ph
), 
UserBadges AS (
    SELECT 
        u.DisplayName,
        b.Name AS BadgeName,
        b.Class,
        b.Date
    FROM 
        Badges b
    JOIN 
        Users u ON u.Id = b.UserId
    WHERE 
        b.Date > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
), 
ClosePosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  
    GROUP BY 
        ph.PostId
)

SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COALESCE(c.CloseCount, 0) AS CloseCount,
    ub.BadgeName,
    ub.Class AS BadgeClass
FROM 
    PostScores p
LEFT JOIN 
    ClosePosts c ON p.PostId = c.PostId
LEFT JOIN 
    (SELECT 
         ub.DisplayName, 
         MAX(ub.BadgeName) AS BadgeName, 
         MAX(ub.Class) AS Class
     FROM 
         UserBadges ub
     GROUP BY 
         ub.DisplayName) ub ON ub.DisplayName = (SELECT DisplayName FROM Users WHERE Id = p.PostId)
WHERE 
    p.rn = 1  
ORDER BY 
    p.Score DESC, 
    p.ViewCount DESC
LIMIT 10;