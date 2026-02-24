WITH PostStatistics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        SUM(vs.VoteCount) AS TotalVotes
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(Id) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) vs ON p.Id = vs.PostId
    GROUP BY 
        pt.Name
)

SELECT 
    *,
    CASE 
        WHEN TotalPosts > 0 THEN TotalVotes / TotalPosts 
        ELSE 0 
    END AS VotesPerPost
FROM 
    PostStatistics
ORDER BY 
    TotalPosts DESC;