WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.Score > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostActivity AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5)
    GROUP BY 
        ph.PostId, ph.UserId
)
SELECT 
    u.DisplayName,
    ur.TotalBadges,
    ur.TotalBounties,
    rp.Title,
    rp.Score,
    pa.EditCount,
    pa.LastEditDate
FROM 
    Users u
LEFT JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN 
    PostActivity pa ON rp.Id = pa.PostId AND pa.UserId = u.Id
WHERE 
    ur.TotalBadges > 0 OR ur.TotalBounties > 0
ORDER BY 
    u.Reputation DESC, rp.Score DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
