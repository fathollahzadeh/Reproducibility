WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(o.DisplayName, 'Community User') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY o.Location ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Users o ON p.OwnerUserId = o.Id 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '90 days'
)

SELECT 
    rp.OwnerDisplayName,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.TotalBounty,
    CASE 
        WHEN rp.CommentCount > 0 THEN 'Has Comments' 
        ELSE 'No Comments' 
    END AS Comment_Status,
    CASE 
        WHEN (rp.Score IS NULL OR rp.Score < 0) THEN 'Negative Score'
        WHEN (rp.Score >= 0 AND rp.Score < 10) THEN 'Low Score'
        WHEN (rp.Score >= 10 AND rp.Score < 50) THEN 'Moderate Score'
        ELSE 'High Score'
    END AS Score_Category,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM PostHistory ph 
            WHERE ph.PostId = rp.PostId AND ph.PostHistoryTypeId = 10
        ) THEN 'Closed'
        ELSE 'Open'
    END AS Post_Status,
    CASE 
        WHEN TotalBounty > 0 THEN 'Has Bounty'
        ELSE 'No Bounty'
    END AS Bounty_Status,
    COALESCE(NULLIF(NULLIF(rp.OwnerDisplayName, ''), 'Community User'), 'Unknown Owner') AS CleanedOwnerDisplayName
FROM 
    RankedPosts rp
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;