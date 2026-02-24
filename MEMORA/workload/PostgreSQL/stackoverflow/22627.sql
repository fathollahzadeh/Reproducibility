WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        DENSE_RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByScore,
        LEAD(p.CreationDate) OVER (ORDER BY p.CreationDate) AS NextPostDate
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.PostTypeId = 1  
), 
PostVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
), 
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
) 
SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(pvc.UpVotes, 0) AS TotalUpVotes,
    COALESCE(pvc.DownVotes, 0) AS TotalDownVotes,
    rp.ViewCount,
    rp.Score,
    rp.RankByScore,
    phs.HistoryTypes,
    phs.LastHistoryDate,
    CASE 
        WHEN phs.LastHistoryDate IS NULL THEN 'No history available'
        ELSE 'History available'
    END AS HistoryStatus,
    CASE 
        WHEN rp.NextPostDate IS NULL THEN 'Latest Post'
        ELSE 'Not the latest'
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteCounts pvc ON rp.Id = pvc.PostId
LEFT JOIN 
    PostHistorySummary phs ON rp.Id = phs.PostId
WHERE 
    rp.RankByScore <= 5
ORDER BY 
    rp.RankByScore, 
    rp.Score DESC;