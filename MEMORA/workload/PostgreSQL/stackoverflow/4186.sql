WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
),
AggregatedUserStats AS (
    SELECT 
        u.Id AS UserId,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id
),
CloseReasons AS (
    SELECT 
        ph.PostId, 
        ARRAY_AGG(DISTINCT crt.Name) AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment::int = crt.Id
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
    au.TotalBounty,
    au.TotalPosts,
    au.TotalViews,
    cr.CloseReasons
FROM 
    RankedPosts rp
LEFT JOIN 
    AggregatedUserStats au ON rp.PostId = au.UserId
LEFT JOIN 
    CloseReasons cr ON rp.PostId = cr.PostId
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.Score DESC, 
    au.TotalViews DESC
LIMIT 100;