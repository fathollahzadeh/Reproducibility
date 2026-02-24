WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        COALESCE(u.DisplayName, 'Unknown User') AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '365 days'
),
PostScores AS (
    SELECT 
        PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId IN (10, 12) THEN 1 ELSE 0 END) AS DeletionVotes
    FROM 
        Votes v
    GROUP BY 
        PostId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        ps.UpVotes,
        ps.DownVotes,
        rp.OwnerDisplayName,
        CASE 
            WHEN rp.Rank = 1 THEN 'Top Post'
            WHEN rp.Rank > 1 AND rp.Rank <= 5 THEN 'High Scorer'
            ELSE 'Regular Post'
        END AS PostCategory
    FROM 
        RankedPosts rp
    JOIN 
        PostScores ps ON rp.PostId = ps.PostId
    WHERE 
        ps.UpVotes IS NOT NULL AND ps.DownVotes IS NOT NULL
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        rct.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes rct ON ph.Comment = CAST(rct.Id AS varchar)
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
)

SELECT 
    pd.Title,
    pd.OwnerDisplayName,
    pd.Score,
    pd.UpVotes,
    pd.DownVotes,
    pd.PostCategory,
    cp.CloseReason,
    COALESCE(NULLIF(pd.Score, 0), 0) AS AdjustedScore 
FROM 
    PostDetails pd
LEFT JOIN 
    ClosedPosts cp ON pd.PostId = cp.PostId
WHERE 
    (cp.CloseReason IS NULL OR pd.Score > 10) 
ORDER BY 
    pd.Score DESC,
    pd.UpVotes DESC
LIMIT 100;