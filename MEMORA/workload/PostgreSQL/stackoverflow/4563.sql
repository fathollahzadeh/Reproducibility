
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        SUM(COALESCE(v.BountyAmount, 0)) OVER (PARTITION BY p.OwnerUserId) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE 
        p.ViewCount > 100
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId, ph.UserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    u.DisplayName,
    p.Title,
    p.CreationDate,
    p.Score,
    r.TotalBounty,
    e.LastEditDate,
    s.PostCount,
    s.TotalBadgeClass
FROM 
    RankedPosts r
JOIN 
    Posts p ON r.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    RecentEdits e ON p.Id = e.PostId
JOIN 
    UserStats s ON u.Id = s.UserId
WHERE 
    r.rn = 1 AND 
    (s.PostCount > 5 OR s.TotalBadgeClass > 1)
ORDER BY 
    p.Score DESC, p.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;
