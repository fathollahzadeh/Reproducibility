
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 
        AND (rp.UpVoteCount - rp.DownVoteCount) >= 5
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS EditDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)  
),
AggregatedHistory AS (
    SELECT 
        ph.PostId,
        MAX(ph.EditDate) AS LastEditDate,
        STRING_AGG(ph.CloseReason, ', ') AS CloseReasons
    FROM 
        PostHistoryData ph
    GROUP BY 
        ph.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.CommentCount,
    ah.LastEditDate,
    ah.CloseReasons
FROM 
    FilteredPosts fp
LEFT JOIN 
    AggregatedHistory ah ON fp.PostId = ah.PostId
WHERE 
    ah.CloseReasons IS NOT NULL OR ah.LastEditDate < fp.CreationDate
ORDER BY 
    fp.ViewCount DESC, 
    fp.Score DESC
LIMIT 100;
