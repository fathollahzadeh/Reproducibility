
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER(PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON CAST(ph.Comment AS INTEGER) = ctr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Title,
    rp.Score,
    rp.ViewCount,
    us.TotalUpVotes,
    us.TotalDownVotes,
    us.BadgeCount,
    COALESCE(cp.CloseCount, 0) AS TotalCloseCount,
    COALESCE(cp.CloseReasons, 'No Close Reasons') AS CloseReasons
FROM 
    RankedPosts rp
JOIN 
    UserStats us ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = us.UserId)
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.Score DESC, 
    us.BadgeCount DESC;
