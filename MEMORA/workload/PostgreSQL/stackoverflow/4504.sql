
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(v.Id), 0) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
), ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN ph.PostHistoryTypeId = 10 THEN c.Name END) AS CloseReason
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes c ON ph.Comment = CAST(c.Id AS VARCHAR)
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) /* Close or Reopen */
    GROUP BY 
        ph.PostId
)
SELECT 
    up.DisplayName,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    us.TotalVotes,
    us.TotalBounties,
    COALESCE(cpr.CloseReason, 'Not Closed') AS CloseReason
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
LEFT JOIN 
    UserStats us ON up.Id = us.UserId
LEFT JOIN 
    ClosedPostReasons cpr ON rp.PostId = cpr.PostId
WHERE 
    rp.Rank = 1
ORDER BY 
    rp.Score DESC,
    us.TotalBounties DESC;
