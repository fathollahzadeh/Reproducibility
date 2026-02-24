
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByCreation,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.Score, p.PostTypeId
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount,
        STRING_AGG(ph.Comment, ', ') AS AllComments,
        MAX(ph.CreationDate) AS LastUpdated
    FROM 
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId IN (10, 11, 12, 13)
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
FilteredRankedPosts AS (
    SELECT 
        rp.*, 
        COALESCE(pa.HistoryCount, 0) AS CloseOpenStatus,
        pa.AllComments,
        pa.LastUpdated
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryAggregates pa ON rp.PostId = pa.PostId
    WHERE 
        rp.RankByCreation = 1
        AND (rp.CommentCount IS NULL OR rp.CommentCount >= 2)
)

SELECT 
    p.Title, 
    p.Score, 
    p.CommentCount, 
    p.UpvoteCount, 
    p.DownvoteCount,
    CASE 
        WHEN p.CloseOpenStatus > 0 THEN 'Closed/Open action taken' 
        ELSE 'No recent action on post' 
    END AS ActionStatus,
    COALESCE(p.AllComments, 'No comments available') AS Comments,
    COALESCE(CAST(p.LastUpdated AS VARCHAR), 'Never updated') AS LastUpdateRecord
FROM 
    FilteredRankedPosts p
ORDER BY 
    p.Score DESC
LIMIT 10;
