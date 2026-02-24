WITH RECURSIVE PostHierarchy AS (
    SELECT 
        Id,
        ParentId,
        Title,
        Score,
        CreationDate,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.Score,
        p.CreationDate,
        ph.Level + 1 AS Level
    FROM 
        Posts p
    JOIN 
        PostHierarchy ph ON p.ParentId = ph.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(v.DownVoteCount, 0) AS DownVoteCount,
        ph.Level,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN PostHierarchy ph ON p.Id = ph.Id
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        MAX(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS LastClosedDate,
        COUNT(CASE WHEN pht.Name = 'Post Closed' THEN 1 END) AS CloseCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId, ph.UserDisplayName, ph.CreationDate
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score AS PostScore,
    pd.UpVoteCount,
    pd.DownVoteCount,
    pd.CommentCount,
    rph.UserDisplayName AS LastCloser,
    rph.LastClosedDate,
    rph.CloseCount,
    pd.Level
FROM 
    PostDetails pd
LEFT JOIN 
    RecentPostHistory rph ON pd.PostId = rph.PostId
WHERE 
    pd.Score > 0
ORDER BY 
    pd.Score DESC,
    pd.CommentCount DESC,
    pd.CreationDate DESC
LIMIT 50;

