
WITH RecursivePostHistory AS (
    
    SELECT 
        ph.PostId,
        ph.CreationDate AS EditDate,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditVersion
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (2, 4, 6) 
),
RecentUserActivity AS (
    
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        b.Name AS BadgeName,
        b.Date AS BadgeDate,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY b.Date DESC) AS BadgeRank
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Date >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
),
PostStatistics AS (
    
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS TotalComments,
        AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS AvgUpvotes, 
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS TotalDownvotes 
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    p.Title,
    p.CreationDate,
    p.ViewCount,
    ps.TotalComments,
    ps.AvgUpvotes,
    ps.TotalDownvotes,
    MAX(rph.EditDate) AS LastEditDate,
    ru.DisplayName AS RecentUser,
    ru.BadgeName AS RecentBadge
FROM 
    Posts p
LEFT JOIN 
    PostStatistics ps ON p.Id = ps.PostId
LEFT JOIN 
    RecursivePostHistory rph ON p.Id = rph.PostId
LEFT JOIN 
    (SELECT * FROM RecentUserActivity WHERE BadgeRank = 1) ru ON ru.UserId = p.OwnerUserId
WHERE 
    p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    AND (ps.TotalComments > 0 OR ps.AvgUpvotes > 5) 
    AND p.ClosedDate IS NULL 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, ps.TotalComments, ps.AvgUpvotes, ps.TotalDownvotes, ru.DisplayName, ru.BadgeName
ORDER BY 
    p.ViewCount DESC, LastEditDate DESC;
