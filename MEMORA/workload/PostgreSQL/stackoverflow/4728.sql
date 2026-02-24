WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        AVG(v.BountyAmount) OVER (PARTITION BY p.Id) AS AvgBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId = 8
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    COALESCE(ph.EditCount, 0) AS TotalEdits,
    CASE 
        WHEN rp.UserRank = 1 THEN 'Top Post'
        WHEN rp.UserRank <= 5 THEN 'High Score Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryCounts ph ON rp.PostId = ph.PostId
WHERE 
    rp.CommentCount > 0 
    AND (rp.AvgBounty IS NULL OR rp.AvgBounty >= 10)
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;