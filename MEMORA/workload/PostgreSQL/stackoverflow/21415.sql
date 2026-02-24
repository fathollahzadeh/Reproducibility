WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY xtype.Name ORDER BY p.Score DESC) AS Rank,
        COUNT(*) OVER (PARTITION BY xtype.Name) AS TotalPosts
    FROM 
        Posts p
    JOIN 
        PostTypes xtype ON p.PostTypeId = xtype.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostWithVotes AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        (COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) - COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0)) AS NetVotes,
        (rp.Score + COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN v.BountyAmount ELSE 0 END), 0)) AS AdjustedScore
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.Comment AS CloseReason,
        ph.CreationDate AS ClosedDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    pw.PostId,
    pw.Title,
    pw.CreationDate,
    pw.Score,
    pw.ViewCount,
    pw.UpVotes,
    pw.DownVotes,
    pw.NetVotes,
    pw.AdjustedScore,
    COALESCE(ps.EditCount, 0) AS TotalEdits,
    COALESCE(cp.CloseReason, 'Not Closed') AS CloseReason,
    COALESCE(cp.ClosedDate, NULL) AS ClosedDate
FROM 
    PostWithVotes pw
LEFT JOIN 
    PostHistorySummary ps ON pw.PostId = ps.PostId
LEFT JOIN 
    ClosedPosts cp ON pw.PostId = cp.PostId
WHERE 
    pw.NetVotes > 0
    AND (pw.AdjustedScore > (SELECT AVG(AdjustedScore) FROM PostWithVotes) OR pw.Score > 50)
ORDER BY 
    pw.NetVotes DESC, pw.AdjustedScore DESC
LIMIT 100;