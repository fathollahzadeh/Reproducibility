
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount,
        COALESCE(AVG(v.BountyAmount), 0) AS AvgBounty,
        T.TagName
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Tags T ON T.WikiPostId = p.Id
        LEFT JOIN Votes v ON v.PostId = p.Id AND v.VoteTypeId = 8  
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)  
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.PostTypeId, T.TagName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.Comment,
        DENSE_RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13, 14)  
        AND ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
),
CombinedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.RankScore,
        rp.CommentCount,
        rp.AvgBounty,
        COALESCE(rph.PostHistoryTypeId, 0) AS LastAction,
        COALESCE(rph.HistoryDate, DATE '9999-12-31') AS LastActionDate
    FROM 
        RankedPosts rp
    LEFT JOIN RecentPostHistory rph ON rp.PostId = rph.PostId AND rph.HistoryRank = 1
)
SELECT 
    cp.PostId,
    cp.Title,
    cp.Score,
    cp.ViewCount,
    cp.RankScore,
    cp.CommentCount,
    cp.AvgBounty,
    cp.LastAction,
    cp.LastActionDate,
    CASE 
        WHEN cp.LastAction IS NULL THEN 'No history'
        WHEN cp.LastAction IN (10, 12) THEN 'Closed/Deleted'
        WHEN cp.LastAction = 11 THEN 'Reopened'
        ELSE 'Locked'
    END AS PostStatus,
    CASE 
        WHEN cp.LastActionDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month' THEN 'Recently Active'
        ELSE 'Inactive'
    END AS ActivityStatus
FROM 
    CombinedPosts cp
WHERE 
    cp.RankScore <= 5  
ORDER BY 
    cp.RankScore;
