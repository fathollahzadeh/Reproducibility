WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS TotalUpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS TotalDownVotes,
        (CASE 
            WHEN p.ClosedDate IS NOT NULL THEN 'Closed' 
            ELSE 'Open' 
        END) AS PostStatus
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (2, 4, 6, 24) THEN 1 END) AS EditCount,
        MAX(ph.CreationDate) AS LastEdited
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
TopPosts AS (
    SELECT 
        rp.*,
        COALESCE(pHS.CloseCount, 0) AS CloseCount,
        COALESCE(pHS.ReopenCount, 0) AS ReopenCount,
        COALESCE(pHS.EditCount, 0) AS EditCount,
        pHS.LastEdited
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistorySummary pHS ON rp.PostId = pHS.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.Author,
    tp.RankScore,
    tp.TotalUpVotes,
    tp.TotalDownVotes,
    tp.PostStatus,
    tp.CloseCount,
    tp.ReopenCount,
    tp.EditCount,
    tp.LastEdited,
    CASE 
        WHEN tp.CloseCount > tp.ReopenCount THEN 'More Closed' 
        ELSE 'Not More Closed' 
    END AS ClosureTrend
FROM 
    TopPosts tp
WHERE 
    tp.RankScore <= 10 
    AND tp.PostStatus = 'Open'
ORDER BY 
    tp.Score DESC;