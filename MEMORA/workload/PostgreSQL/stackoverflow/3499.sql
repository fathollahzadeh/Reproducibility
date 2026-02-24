
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
        AND p.Score > 5
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        MAX(ph.CreationDate) OVER (PARTITION BY ph.PostId) AS LastCloseAttempt,
        COUNT(*) AS CloseReasonCount
    FROM 
        PostHistory ph 
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    ue.DisplayName,
    ue.CommentCount,
    ce.ClosedDate,
    ce.CloseReasonCount
FROM 
    RankedPosts rp
LEFT JOIN 
    UserEngagement ue ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ue.UserId)
LEFT JOIN 
    ClosedPosts ce ON rp.PostId = ce.PostId
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Score DESC, ue.TotalBounty DESC
LIMIT 50;
