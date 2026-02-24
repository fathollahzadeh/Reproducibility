
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        COUNT(*) AS CloseReasonCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  
    GROUP BY 
        ph.PostId, ph.UserId
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        COALESCE(cp.CloseReasonCount, 0) AS CloseReasonCount,
        CASE 
            WHEN rp.Score IS NULL THEN 'Score Not Calculated' 
            WHEN rp.Score >= 100 THEN 'High Score'
            WHEN rp.Score > 0 AND rp.Score < 100 THEN 'Medium Score'
            ELSE 'Low Score' 
        END AS ScoreCategory 
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.CommentCount,
    pm.UpVotes,
    pm.DownVotes,
    pm.CloseReasonCount,
    pm.ScoreCategory
FROM 
    PostMetrics pm
WHERE 
    pm.CloseReasonCount > 0 
    OR pm.ScoreCategory = 'High Score'
ORDER BY 
    pm.Score DESC, 
    pm.CommentCount DESC;
