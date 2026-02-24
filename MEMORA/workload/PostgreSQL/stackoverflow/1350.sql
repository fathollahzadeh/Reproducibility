
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(v.UserId, 0) AS UpvoteUserId,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, v.UserId
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndeleteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    COALESCE(phc.CloseReopenCount, 0) AS CloseReopenActivity,
    COALESCE(phc.DeleteUndeleteCount, 0) AS DeleteUndeleteActivity,
    CASE 
        WHEN rp.OwnerPostRank <= 3 THEN 'Top Posts'
        ELSE 'Regular Posts'
    END AS PostCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryCounts phc ON rp.PostId = phc.PostId
WHERE 
    rp.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year')
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 100;
