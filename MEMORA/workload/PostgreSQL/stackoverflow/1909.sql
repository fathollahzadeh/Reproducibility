
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), 
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownvoteCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        PostId
), 
PostHistoryCount AS (
    SELECT 
        PostId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory
    WHERE 
        PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.Score,
    COALESCE(phc.EditCount, 0) AS EditCount,
    COALESCE(pvc.UpvoteCount, 0) AS UpvoteCount,
    COALESCE(pvc.DownvoteCount, 0) AS DownvoteCount,
    CASE 
        WHEN COALESCE(phc.EditCount, 0) > 10 THEN 'Highly Edited'
        WHEN COALESCE(phc.EditCount, 0) > 5 THEN 'Moderately Edited'
        ELSE 'Rarely Edited'
    END AS EditLevel,
    CASE 
        WHEN rp.OwnerRank = 1 THEN 'Top Post'
        ELSE 'Other Post'
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryCount phc ON rp.PostId = phc.PostId
LEFT JOIN 
    PostVoteCounts pvc ON rp.PostId = pvc.PostId
WHERE 
    rp.Score > 10
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
