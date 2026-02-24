WITH PostStatistics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore,
        AVG(p.ViewCount) AS AverageViewCount,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalCommentCount,
        SUM(v.VoteCount) AS TotalVotes
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT PostId, VoteTypeId, COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId, VoteTypeId
    ) v ON p.Id = v.PostId
    GROUP BY 
        pt.Name
)

SELECT 
    PostType,
    PostCount,
    AverageScore,
    AverageViewCount,
    TotalCommentCount,
    TotalVotes
FROM 
    PostStatistics
ORDER BY 
    PostCount DESC;