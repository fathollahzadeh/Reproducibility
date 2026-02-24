
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId, p.ViewCount
),
ClosedPosts AS (
    SELECT 
        postId, 
        COUNT(*) AS CloseCount
    FROM 
        PostHistory
    WHERE 
        PostHistoryTypeId = 10
    GROUP BY 
        postId
)
SELECT 
    up.DisplayName,
    rp.PostID,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    rp.ViewCount,
    rp.CommentCount,
    rp.TotalBounties
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
LEFT JOIN 
    ClosedPosts cp ON rp.PostID = cp.PostId
WHERE 
    rp.Rank = 1
AND 
    rp.Score > 0
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
FETCH FIRST 10 ROWS ONLY;
