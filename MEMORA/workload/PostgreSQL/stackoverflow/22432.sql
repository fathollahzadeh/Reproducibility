
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        us.TotalBounties
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        UserStats us ON c.UserId = us.UserId
    WHERE 
        rp.Rank <= 10
        AND us.BadgeCount > 0
        AND us.TotalBounties > (
            SELECT 
                AVG(TotalBounties) 
            FROM 
                UserStats
        )
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    cp.CloseCount,
    cp.ReopenCount,
    us.DisplayName AS TopContributor
FROM 
    FilteredPosts fp
LEFT JOIN 
    ClosedPosts cp ON fp.PostId = cp.PostId
LEFT JOIN 
    Comments c ON fp.PostId = c.PostId 
LEFT JOIN 
    Users us ON c.UserId = us.Id
WHERE 
    cp.CloseCount > 0
    OR fp.TotalBounties > 25
ORDER BY 
    fp.ViewCount DESC,
    fp.Title ASC
LIMIT 20 OFFSET 0;
