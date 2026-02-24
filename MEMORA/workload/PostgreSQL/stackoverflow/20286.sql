
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.Score > 0
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        MAX(p.LastActivityDate) AS LastActivity
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN CloseReasonTypes cr ON CAST(ph.Comment AS INT) = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    ua.PostCount,
    ua.TotalBounty,
    ua.LastActivity,
    rp.Title,
    rp.Score,
    cr.CloseReasons
FROM 
    UserActivity ua
JOIN Users u ON ua.UserId = u.Id
LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.Rank = 1
LEFT JOIN CloseReasons cr ON rp.PostId = cr.PostId
WHERE 
    ua.LastActivity > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
    AND (COALESCE(cr.CloseReasons, '') <> '' OR rp.Score > 10)
ORDER BY 
    ua.TotalBounty DESC, ua.PostCount DESC, rp.Score DESC NULLS LAST;
