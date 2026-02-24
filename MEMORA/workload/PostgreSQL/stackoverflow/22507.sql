
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(SUM(v.BountyAmount) FILTER (WHERE v.VoteTypeId = 8), 0) AS TotalBounty,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        CASE 
            WHEN p.Body IS NULL THEN 'No Content' 
            ELSE CONCAT(SUBSTRING(p.Body, 1, 100), '...') 
        END AS PreviewBody
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        CASE 
            WHEN u.LastAccessDate < (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year') THEN 'Inactive'
            ELSE 'Active'
        END AS Status
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId, 
        MAX(ph.CreationDate) AS LastEdited
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
)
SELECT 
    up.DisplayName,
    up.Reputation,
    up.Status,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(rp.CommentCount, 0) AS CommentCount,
    rp.PreviewBody,
    phi.LastEdited,
    rp.TotalBounty
FROM 
    RankedPosts rp
JOIN 
    UserReputation up ON rp.OwnerUserId = up.UserId
LEFT JOIN 
    PostHistoryInfo phi ON rp.PostId = phi.PostId
WHERE 
    rp.rn = 1 
    AND rp.Score > 10 
    AND rp.ViewCount > (SELECT AVG(ViewCount) FROM Posts)
ORDER BY 
    COALESCE(rp.TotalBounty, 0) DESC, 
    up.Reputation DESC
FETCH FIRST 50 ROWS ONLY;
