
WITH RecursivePostHistory AS (
    SELECT 
        ph.Id AS PostHistoryId,
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.Text,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostId IS NOT NULL
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.PostId) AS CloseCount
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        p.Id
)
SELECT 
    u.DisplayName,
    u.TotalPosts,
    u.TotalComments,
    u.TotalBounty,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    COALESCE(rph.PostHistoryId, 0) AS LastPostHistoryId,
    COALESCE(rph.CreationDate, DATE '1970-01-01') AS LastPostHistoryDate
FROM 
    UserActivity u
LEFT JOIN 
    ClosedPosts cp ON u.UserId = cp.PostId
LEFT JOIN 
    RecursivePostHistory rph ON u.TotalPosts > 0 AND rph.rn = 1
WHERE 
    (u.TotalPosts > 10 OR u.TotalComments > 5)
    AND (u.TotalBounty IS NULL OR u.TotalBounty > 20)
ORDER BY 
    u.TotalBounty DESC, 
    u.TotalPosts DESC
LIMIT 100;
