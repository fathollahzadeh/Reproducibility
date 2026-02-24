
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount,
        COUNT(DISTINCT c.Id) AS TotalComments,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC, p.Title) AS ViewRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate
), UserBounties AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBountySpent
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId = 8 
    GROUP BY 
        u.Id, u.DisplayName
), ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate,
        COUNT(*) AS CloseCount,
        ARRAY_AGG(DISTINCT crt.Name) AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON CAST(ph.Comment AS INT) = crt.Id 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    cp.FirstClosedDate,
    cp.CloseCount,
    cp.CloseReasons,
    ub.DisplayName,
    ub.TotalBountySpent,
    rp.TotalBountyAmount,
    CASE 
        WHEN rp.ViewRank = 1 
        THEN 'Most Viewed' 
        ELSE 'Regular Post' 
    END AS PostTag,
    CASE 
        WHEN cp.CloseCount > 0 
        THEN 'Closed'
        ELSE 'Active' 
    END AS Status
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBounties ub ON rp.PostId = ub.UserId 
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.TotalComments > 0
ORDER BY 
    rp.ViewCount DESC, 
    rp.TotalBountyAmount DESC;
