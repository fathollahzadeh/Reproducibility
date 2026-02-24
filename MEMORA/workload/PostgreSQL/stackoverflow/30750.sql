
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  

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
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        ROW_NUMBER() OVER (ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) > 100  
),
RecentComments AS (
    SELECT 
        c.Id,
        c.PostId,
        c.UserDisplayName,
        c.Text,
        c.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY c.PostId ORDER BY c.CreationDate DESC) AS CommentRank
    FROM 
        Comments c
)
SELECT 
    ph.PostId,
    ph.Title,
    u.UserId,
    u.DisplayName AS TopUserDisplayName,
    u.UpVotes,
    u.DownVotes,
    comments.UserDisplayName AS LastCommentUser,
    comments.Text AS LastCommentText
FROM 
    PostHierarchy ph
LEFT JOIN 
    TopUsers u ON ph.PostId IN (SELECT ParentId FROM Posts WHERE Id = ph.PostId)
LEFT JOIN 
    RecentComments comments ON ph.PostId = comments.PostId AND comments.CommentRank = 1
WHERE 
    ph.Level <= 3  
ORDER BY 
    ph.PostId;
