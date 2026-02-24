WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount 
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.PostTypeId, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        COALESCE(MAX(ph.Comment), 'No reason provided') AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseEventRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId, ph.CreationDate
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        cp.CloseReason
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId AND cp.CloseEventRank = 1 
)
SELECT 
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    pd.CloseReason,
    CASE 
        WHEN pd.Score IS NULL THEN 'No Score' 
        WHEN pd.Score > 0 THEN 'Positive' 
        WHEN pd.Score < 0 THEN 'Negative' 
        ELSE 'Neutral' 
    END AS ScoreCategory,
    CASE 
        WHEN pd.CommentCount > 100 THEN 'Highly Discussed Post'
        WHEN pd.CommentCount BETWEEN 50 AND 100 THEN 'Moderately Discussed Post'
        ELSE 'Less Discussed Post'
    END AS DiscussionLevel
FROM 
    PostDetails pd
WHERE 
    pd.CloseReason IS NOT NULL
ORDER BY 
    pd.ViewCount DESC, pd.Score DESC
LIMIT 10;