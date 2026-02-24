WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
),
PostHistories AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        COUNT(ph.Id) AS EditCount,
        STRING_AGG(DISTINCT CASE 
            WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 'Edited'
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed'
            ELSE NULL
        END, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
AggregatedVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(av.UpVotes, 0) AS UpVotes,
    COALESCE(av.DownVotes, 0) AS DownVotes,
    rp.ViewCount,
    ph.FirstEditDate,
    ph.EditCount,
    ph.HistoryTypes,
    CASE 
        WHEN rp.Rank <= 5 THEN 'Top Ranked Post'
        WHEN rp.CommentCount > 10 THEN 'Highly Discussed'
        ELSE 'Standard Post'
    END AS PostCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistories ph ON rp.PostId = ph.PostId
LEFT JOIN 
    AggregatedVotes av ON rp.PostId = av.PostId
WHERE 
    rp.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    AND (ph.EditCount IS NULL OR ph.EditCount > 0) 
ORDER BY 
    rp.Score DESC,
    rp.ViewCount DESC
FETCH FIRST 100 ROWS ONLY;