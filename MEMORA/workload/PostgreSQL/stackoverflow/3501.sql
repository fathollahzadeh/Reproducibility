WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as Rank,
        COALESCE(u.DisplayName, 'Anonymous') as OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
),
PostDetails AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        COALESCE(c.CommentCount, 0) as CommentCount,
        COALESCE(v.TotalVotes, 0) as TotalVotes,
        CASE 
            WHEN rp.Score >= 10 THEN 'High Score'
            WHEN rp.Score < 10 AND rp.Score >= 5 THEN 'Medium Score'
            ELSE 'Low Score'
        END as ScoreCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        (SELECT PostId, COUNT(*) as CommentCount 
         FROM Comments 
         GROUP BY PostId) c ON rp.Id = c.PostId
    LEFT JOIN 
        (SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) as TotalVotes 
         FROM Votes 
         GROUP BY PostId) v ON rp.Id = v.PostId
    WHERE 
        rp.Rank <= 5
),
ClosedPosts AS (
    SELECT 
        p.Id, 
        ph.Comment, 
        ph.CreationDate as ClosedOn, 
        'Closed Reason: ' || COALESCE(cr.Name, 'Unknown') AS CloseReasonDetail 
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    pd.Title,
    pd.OwnerDisplayName,
    pd.Score,
    pd.CommentCount,
    pd.TotalVotes,
    pd.ScoreCategory,
    cp.ClosedOn,
    cp.CloseReasonDetail
FROM 
    PostDetails pd
LEFT JOIN 
    ClosedPosts cp ON pd.Id = cp.Id
ORDER BY 
    pd.Score DESC, pd.CommentCount DESC;