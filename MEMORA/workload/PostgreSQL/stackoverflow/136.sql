
WITH RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        ph.UserId AS CloserId,
        crt.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON CAST(ph.Comment AS INTEGER) = crt.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
)
SELECT 
    up.UserId,
    up.Reputation,
    up.TotalBounty,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    cp.CloseDate,
    cp.CloseReason
FROM 
    UserReputation up
JOIN 
    RecentPosts rp ON up.UserId = rp.OwnerUserId
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId
WHERE 
    up.Reputation >= 100
AND 
    rp.rn = 1
ORDER BY 
    up.Reputation DESC, rp.Score DESC
LIMIT 50;
