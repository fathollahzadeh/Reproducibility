
WITH RECURSIVE PostHierarchy AS (
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        1 AS Level,
        p.CreationDate
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  

    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        ph.Level + 1,
        p.CreationDate
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
    WHERE 
        p.PostTypeId = 2  
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentPosts AS (
    SELECT 
        ph.PostId,
        ph.Title,
        ph.OwnerUserId,
        ph.Level,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.OwnerUserId ORDER BY ph.CreationDate DESC) AS RecentRank
    FROM 
        PostHierarchy ph
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 DAYS'
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ur.BadgeCount,
    ur.TotalBounty,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostCreationDate
FROM 
    UserReputation ur
LEFT JOIN 
    RecentPosts rp ON ur.UserId = rp.OwnerUserId
LEFT JOIN 
    Users u ON ur.UserId = u.Id
WHERE 
    rp.RecentRank = 1  
ORDER BY 
    ur.Reputation DESC,  
    rp.CreationDate DESC  
LIMIT 50;
