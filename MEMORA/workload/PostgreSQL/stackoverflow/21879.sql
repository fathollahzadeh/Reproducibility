WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '10 days'
        AND p.Score IS NOT NULL
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
    WHERE 
        u.Reputation > 1000
    GROUP BY
        u.Id, u.Reputation
),
PostEditHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        COUNT(*) OVER (PARTITION BY ph.PostId) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.Comment AS CloseReason,
        ph.CreationDate AS CloseDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    ur.Reputation,
    ur.TotalBounty,
    pe.EditCount,
    cp.CloseReason,
    cp.CloseDate,
    CASE
        WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
        WHEN rp.Score > 0 AND pe.EditCount > 0 THEN 'Edited and Popular'
        WHEN cp.CloseReason IS NOT NULL THEN 'Closed: ' || cp.CloseReason
        ELSE 'Open'
    END AS PostState
FROM 
    RankedPosts rp
LEFT JOIN 
    UserReputation ur ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId LIMIT 1)
LEFT JOIN 
    PostEditHistory pe ON pe.PostId = rp.PostId
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = rp.PostId
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate ASC;