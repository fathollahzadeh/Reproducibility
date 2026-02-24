
WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        COUNT(C.Id) AS CommentCount,
        COUNT(A.Id) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(EXTRACT(EPOCH FROM V.CreationDate)) AS AverageVoteDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= '2020-01-01'
    GROUP BY 
        P.Id, P.PostTypeId
)
SELECT 
    PT.Name AS PostTypeName,
    COUNT(PS.PostId) AS TotalPosts,
    SUM(PS.CommentCount) AS TotalComments,
    SUM(PS.AnswerCount) AS TotalAnswers,
    SUM(PS.UpVotes) AS TotalUpVotes,
    SUM(PS.DownVotes) AS TotalDownVotes,
    AVG(PS.AverageVoteDate) AS AvgVoteDate
FROM 
    PostStatistics PS
JOIN 
    PostTypes PT ON PS.PostTypeId = PT.Id
GROUP BY 
    PT.Name
ORDER BY 
    TotalPosts DESC;
