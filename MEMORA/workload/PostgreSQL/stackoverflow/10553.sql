SELECT 
    p.PostTypeId,
    COUNT(p.Id) AS PostCount,
    AVG(p.ViewCount) AS AverageViewCount,
    SUM(COALESCE(c.CommentCount, 0)) AS TotalComments,
    SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes
FROM 
    Posts p
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(Id) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
) c ON p.Id = c.PostId
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(Id) AS VoteCount
    FROM 
        Votes
    GROUP BY 
        PostId
) v ON p.Id = v.PostId
GROUP BY 
    p.PostTypeId
ORDER BY 
    PostCount DESC;