WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL
        AND p.ViewCount > 100
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name LIKE 'Up%' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name LIKE 'Down%' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        v.PostId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rv.VoteCount,
        rv.UpVotes,
        rv.DownVotes,
        COALESCE(p.HistoryCount, 0) AS HistoryCount,
        p.HistoryTypes,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC, rv.VoteCount DESC) AS OverallRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId
    LEFT JOIN 
        PostHistorySummary p ON rp.PostId = p.PostId
    WHERE 
        rp.Rank <= 5  
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.VoteCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.HistoryCount,
    tp.HistoryTypes,
    ntile(10) OVER (ORDER BY tp.Score DESC) AS ScoreDecile
FROM 
    TopPosts tp
WHERE 
    tp.HistoryCount > 0
ORDER BY 
    tp.OverallRank
LIMIT 20;