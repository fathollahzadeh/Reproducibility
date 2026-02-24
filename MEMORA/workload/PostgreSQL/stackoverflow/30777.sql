WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
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
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
), 
PostStats AS (
    SELECT 
        ph.PostId,
        ph.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,  
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownvoteCount,  
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        PostHierarchy ph
    LEFT JOIN 
        Comments c ON ph.PostId = c.PostId
    LEFT JOIN 
        Votes v ON ph.PostId = v.PostId
    GROUP BY 
        ph.PostId, ph.Title
), 
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        COUNT(DISTINCT v.Id) AS VotesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        PostsCreated DESC
    LIMIT 5
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    COALESCE(au.DisplayName, 'No User') AS LastVoter,
    CASE 
        WHEN ps.LastVoteDate IS NOT NULL THEN 'Active'
        ELSE 'Inactive'
    END AS PostActivity,
    ROW_NUMBER() OVER (PARTITION BY ph.Level ORDER BY ps.UpvoteCount DESC) AS Rank
FROM 
    PostStats ps
LEFT JOIN 
    Users au ON au.Id = (SELECT UserId FROM Votes v WHERE v.PostId = ps.PostId ORDER BY v.CreationDate DESC LIMIT 1)
LEFT JOIN 
    MostActiveUsers mau ON mau.UserId IN (SELECT DISTINCT c.UserId FROM Comments c WHERE c.PostId = ps.PostId)
JOIN 
    PostHierarchy ph ON ps.PostId = ph.PostId
ORDER BY 
    ps.UpvoteCount DESC, ps.CommentCount DESC;