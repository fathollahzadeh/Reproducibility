
WITH RECURSIVE RecursivePostHierarchy AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.ParentId, 
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.ParentId, 
        rph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 END) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostScoreRanked AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    JOIN 
        PostVoteStats ps ON p.Id = ps.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Score, ps.UpVotes, ps.DownVotes
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title, 
        ph.UserDisplayName AS LastEditor,
        ph.CreationDate AS CloseDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10  
)
SELECT 
    p.Title AS QuestionTitle,
    ph.Title AS ParentTitle,
    p.Score AS QuestionScore,
    COALESCE(ups.UpVotes, 0) AS UpVotes,
    COALESCE(downs.DownVotes, 0) AS DownVotes,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    cp.LastEditor AS ClosedBy,
    cp.CloseDate,
    ph.Level AS HierarchyLevel
FROM 
    PostScoreRanked p
LEFT JOIN 
    RecursivePostHierarchy ph ON p.Id = ph.Id
LEFT JOIN 
    ClosedPosts cp ON p.Id = cp.Id
LEFT JOIN 
    PostVoteStats ups ON p.Id = ups.PostId
LEFT JOIN 
    PostVoteStats downs ON p.Id = downs.PostId
LEFT JOIN 
    (SELECT 
        PostId, 
        COUNT(*) AS CommentCount 
     FROM 
        Comments 
     GROUP BY 
        PostId) c ON p.Id = c.PostId
WHERE 
    p.Score > 0
ORDER BY 
    p.Score DESC, 
    p.ScoreRank;
