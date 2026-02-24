
WITH CommentedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        c.UserId AS CommenterId,
        c.Text AS CommentText,
        c.CreationDate AS CommentDate
    FROM 
        Posts p
    JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  
        AND c.CreationDate > p.CreationDate
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(c.Id) AS TotalComments
    FROM 
        Users u
    JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostDetails AS (
    SELECT 
        cp.PostId,
        cp.Title,
        cp.CommentText,
        cp.CommentDate,
        up.DisplayName AS CommenterName,
        up.Reputation AS CommenterReputation
    FROM 
        CommentedPosts cp
    JOIN 
        UserReputation up ON cp.CommenterId = up.UserId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CommentText,
    pd.CommentDate,
    pd.CommenterName,
    pd.CommenterReputation,
    COUNT(v.Id) AS VoteCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
FROM 
    PostDetails pd
LEFT JOIN 
    Votes v ON pd.PostId = v.PostId
GROUP BY 
    pd.PostId, pd.Title, pd.CommentText, pd.CommentDate, pd.CommenterName, pd.CommenterReputation
ORDER BY 
    pd.CommentDate DESC, pd.CommenterReputation DESC
LIMIT 100;
