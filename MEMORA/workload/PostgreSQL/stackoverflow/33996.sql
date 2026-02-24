WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVoteCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        PostId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseCount,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 11) AS ReopenCount,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (12, 13)) AS DeleteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Id,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    COALESCE(pvc.UpVoteCount, 0) AS UpVoteCount,
    COALESCE(pvc.DownVoteCount, 0) AS DownVoteCount,
    COALESCE(phs.CloseCount, 0) AS CloseCount,
    COALESCE(phs.ReopenCount, 0) AS ReopenCount,
    COALESCE(phs.DeleteCount, 0) AS DeleteCount,
    CASE 
        WHEN rp.Rank <= 10 THEN 'Top 10 Post'
        ELSE 'Other Post'
    END AS PostCategory,
    CASE 
        WHEN rp.Score >= 0 THEN 'Positive'
        ELSE 'Negative'
    END AS ScoreCategory 
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteCounts pvc ON rp.Id = pvc.PostId
LEFT JOIN 
    PostHistorySummary phs ON rp.Id = phs.PostId
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;