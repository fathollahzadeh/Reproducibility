
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostClosedCount AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
),
PostWithCloseCount AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(pc.CloseCount, 0) AS CloseCount
    FROM 
        Posts p
    LEFT JOIN 
        PostClosedCount pc ON p.Id = pc.PostId
)
SELECT 
    up.UserId,
    up.DisplayName,
    rp.Id AS PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    up.BadgeCount,
    up.TotalBounties,
    pcc.CloseCount
FROM 
    RankedPosts rp
JOIN 
    UserStats up ON rp.Id IN (SELECT AcceptedAnswerId FROM Posts WHERE OwnerUserId = up.UserId)
LEFT JOIN 
    PostWithCloseCount pcc ON rp.Id = pcc.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    up.BadgeCount DESC, 
    rp.Score DESC
FETCH FIRST 100 ROWS ONLY;
