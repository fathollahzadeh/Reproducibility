WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS UserDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
        AND p.ViewCount IS NOT NULL
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UserDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 10
),
VoteAggregation AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(pt.Name, ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastUpdate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        ph.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.UserDisplayName,
    COALESCE(va.UpVotes, 0) AS UpVotes,
    COALESCE(va.DownVotes, 0) AS DownVotes,
    COALESCE(phd.HistoryTypes, 'No history') AS HistoryTypes,
    phd.LastUpdate,
    CASE 
        WHEN fp.Score > 100 THEN 'High Performer'
        WHEN fp.Score BETWEEN 50 AND 100 THEN 'Moderate Performer'
        WHEN fp.Score < 50 THEN 'Low Performer'
        ELSE 'Unknown'
    END AS PerformanceCategory
FROM 
    FilteredPosts fp
LEFT JOIN 
    VoteAggregation va ON fp.PostId = va.PostId
LEFT JOIN 
    PostHistoryDetails phd ON fp.PostId = phd.PostId
WHERE 
    EXISTS (SELECT 1 FROM Comments c WHERE c.PostId = fp.PostId AND c.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days')
ORDER BY 
    fp.Score DESC,
    fp.ViewCount DESC
OFFSET 0 ROWS 
FETCH NEXT 100 ROWS ONLY;