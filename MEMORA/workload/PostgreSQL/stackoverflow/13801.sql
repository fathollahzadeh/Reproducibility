WITH PostStats AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS PostCount,
        COALESCE(SUM(c.CommentCount), 0) AS TotalComments,
        COALESCE(SUM(v.VoteCount), 0) AS TotalVotes
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN (
        SELECT PostId, COUNT(Id) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(Id) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    GROUP BY 
        pt.Name
)

SELECT 
    PostTypeName,
    PostCount,
    TotalComments,
    TotalVotes
FROM 
    PostStats
ORDER BY 
    PostCount DESC;