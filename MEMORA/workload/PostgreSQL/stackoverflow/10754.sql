WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        COUNT(DISTINCT A.Id) AS AnswerCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND P.PostTypeId = 1  
    GROUP BY 
        P.Id, P.PostTypeId, P.CreationDate, P.Score, P.ViewCount
),
BenchmarkResults AS (
    SELECT 
        PostTypeId,
        COUNT(PostId) AS TotalPosts,
        AVG(ViewCount) AS AverageViews,
        AVG(Score) AS AverageScore,
        AVG(CommentCount) AS AverageComments,
        AVG(VoteCount) AS AverageVotes,
        AVG(AnswerCount) AS AverageAnswers
    FROM 
        PostStatistics
    GROUP BY 
        PostTypeId
)
SELECT 
    PT.Name AS PostType,
    BR.TotalPosts,
    BR.AverageViews,
    BR.AverageScore,
    BR.AverageComments,
    BR.AverageVotes,
    BR.AverageAnswers
FROM 
    BenchmarkResults BR
JOIN 
    PostTypes PT ON BR.PostTypeId = PT.Id
ORDER BY 
    BR.TotalPosts DESC;