WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '2 years'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
RecentTopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        us.DisplayName AS UserName,
        rp.Score,
        rp.CreationDate,
        DENSE_RANK() OVER (ORDER BY rp.Score DESC) AS Rank
    FROM 
        RankedPosts rp
    JOIN 
        Users us ON rp.OwnerUserId = us.Id
    WHERE 
        rp.rn = 1
)
SELECT 
    rt.PostId,
    rt.Title,
    rt.UserName,
    rt.Score,
    rt.CreationDate,
    COALESCE(us.BadgeCount, 0) AS BadgeCount,
    COALESCE(us.TotalBounties, 0) AS TotalBounties
FROM 
    RecentTopPosts rt
LEFT JOIN 
    UserStats us ON rt.UserName = us.DisplayName
WHERE 
    rt.Score > 10
ORDER BY 
    rt.Score DESC
LIMIT 50;