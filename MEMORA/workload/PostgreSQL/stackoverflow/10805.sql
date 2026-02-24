WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        th.Name AS PostType,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id) AS TotalVotes,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS TotalComments
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes th ON p.PostTypeId = th.Id
    WHERE 
        p.CreationDate >= '2023-01-01'  
)
SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    AnswerCount,
    CommentCount,
    OwnerDisplayName,
    OwnerReputation,
    PostType,
    TotalVotes,
    TotalComments
FROM 
    PostMetrics
ORDER BY 
    ViewCount DESC
LIMIT 100;