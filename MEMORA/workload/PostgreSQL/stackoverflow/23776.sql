WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS RankScore,
        COALESCE((
            SELECT 
                COUNT(*) 
            FROM 
                Votes v 
            WHERE 
                v.PostId = p.Id 
                AND v.VoteTypeId = 2
        ), 0) AS UpVotes,
        COALESCE((
            SELECT 
                COUNT(*) 
            FROM 
                Votes v 
            WHERE 
                v.PostId = p.Id 
                AND v.VoteTypeId = 3
        ), 0) AS DownVotes
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.RankScore,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.UpVotes + rp.DownVotes > 0 THEN 
                (CAST(rp.UpVotes AS FLOAT) / (rp.UpVotes + rp.DownVotes)) * 100
            ELSE 
                NULL 
        END AS UpVotePercentage,
        CASE 
            WHEN rp.ViewCount > 1000 THEN 'Popular'
            ELSE 'Less Popular'
        END AS Popularity
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 10
),
PostHistories AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        COALESCE(COUNT(DISTINCT ph.Id), 0) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.CreationDate
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    pd.Score,
    pd.UpVotePercentage,
    pd.Popularity,
    ph.EditCount,
    CASE 
        WHEN ph.EditCount IS NULL THEN 'No Edits'
        ELSE 'Edited'
    END AS EditStatus,
    CASE 
        WHEN pd.Score > 10 AND pd.Popularity = 'Popular' THEN 'High Engagement'
        WHEN pd.Score <= 10 AND pd.Popularity = 'Less Popular' THEN 'Low Engagement'
        ELSE 'Moderate Engagement'
    END AS EngagementLevel
FROM 
    PostDetails pd
LEFT JOIN 
    PostHistories ph ON pd.PostId = ph.PostId
WHERE 
    pd.UpVotePercentage IS NOT NULL
ORDER BY 
    pd.ViewCount DESC, pd.Score DESC;