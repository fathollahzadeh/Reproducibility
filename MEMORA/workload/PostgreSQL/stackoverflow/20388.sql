WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS rn,
        COUNT(*) OVER (PARTITION BY pt.Name) AS TotalPostsByType,
        DENSE_RANK() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS rank_creation
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.ViewCount IS NOT NULL
),
LatestVotes AS (
    SELECT 
        PostId,
        COUNT(*) AS VoteCount,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostHistoryCounts AS (
    SELECT 
        PostId,
        COUNT(*) FILTER (WHERE PostHistoryTypeId IN (10, 11, 12, 13)) AS HistoryCount
    FROM 
        PostHistory
    GROUP BY 
        PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    COALESCE(rv.VoteCount, 0) AS TotalVotes,
    COALESCE(rv.UpVotes, 0) AS UpVoteCount,
    COALESCE(rv.DownVotes, 0) AS DownVoteCount,
    rp.Score,
    rp.CreationDate,
    phc.HistoryCount,
    CASE 
        WHEN rp.rank_creation = 1 THEN 'Most Recent'
        WHEN rp.rn <= 3 THEN 'Top 3'
        ELSE 'Others'
    END AS PostRank
FROM 
    RankedPosts rp
LEFT JOIN 
    LatestVotes rv ON rp.PostId = rv.PostId
LEFT JOIN 
    PostHistoryCounts phc ON rp.PostId = phc.PostId
WHERE 
    rp.TotalPostsByType > 1
ORDER BY 
    rp.ViewCount DESC, 
    rp.Score DESC, 
    rp.CreationDate DESC
LIMIT 100;
