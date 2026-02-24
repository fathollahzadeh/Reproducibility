WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2023-01-01' AND
        p.PostTypeId IN (1, 2) 
),
PostHistoryStats AS (
    SELECT
        ph.PostId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastUpdated
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        rp.Rank,
        phs.HistoryCount,
        phs.LastUpdated
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryStats phs ON rp.PostId = phs.PostId
    WHERE 
        phs.HistoryCount > 5 
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.OwnerDisplayName,
    fp.Rank,
    fp.HistoryCount,
    fp.LastUpdated,
    (fp.ViewCount / NULLIF(fp.HistoryCount, 0)) AS ViewsPerHistory,
    COALESCE(voteSummary.UpVotes, 0) AS TotalUpVotes,
    COALESCE(voteSummary.DownVotes, 0) AS TotalDownVotes
FROM 
    FilteredPosts fp
LEFT JOIN (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
) AS voteSummary ON fp.PostId = voteSummary.PostId
ORDER BY 
    fp.Score DESC, 
    fp.LastUpdated DESC
LIMIT 100;