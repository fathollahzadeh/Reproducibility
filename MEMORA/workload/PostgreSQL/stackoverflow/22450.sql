WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(p.AcceptedAnswerId, -1) AS AnswerId 
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.Score > (SELECT AVG(Score) FROM Posts WHERE CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseVoteCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    us.TotalPosts,
    us.TotalBadges,
    us.TotalBounty,
    cp.CloseVoteCount,
    cp.LastClosedDate
FROM 
    RankedPosts rp
JOIN 
    UserStats us ON rp.AnswerId = us.UserId 
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    us.TotalPosts > 5
    AND (cp.CloseVoteCount IS NULL OR cp.LastClosedDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '3 months')
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 100;