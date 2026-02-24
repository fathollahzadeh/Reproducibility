
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
        AND p.Score > 0
),
PostVoteSummary AS (
    SELECT 
        pv.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes pv
    JOIN 
        VoteTypes vt ON pv.VoteTypeId = vt.Id
    GROUP BY 
        pv.PostId
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN pht.Name = 'Post Closed' THEN 1 END) AS ClosureCount,
        COUNT(CASE WHEN pht.Name = 'Post Reopened' THEN 1 END) AS ReopenCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    COALESCE(pha.ClosureCount, 0) AS ClosureCount,
    COALESCE(pha.ReopenCount, 0) AS ReopenCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    CASE 
        WHEN rp.ViewCount > 1000 THEN 'High'
        WHEN rp.ViewCount BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS ViewCountCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteSummary pvs ON rp.Id = pvs.PostId
LEFT JOIN 
    PostHistoryAggregated pha ON rp.Id = pha.PostId
LEFT JOIN 
    Comments c ON rp.Id = c.PostId
WHERE 
    rp.rn = 1
GROUP BY 
    rp.Id, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, 
    pvs.UpVotes, pvs.DownVotes, pha.ClosureCount, pha.ReopenCount
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 50;
