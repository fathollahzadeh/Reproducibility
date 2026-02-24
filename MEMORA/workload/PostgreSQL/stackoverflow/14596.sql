SELECT 
    PT.Name AS PostType,
    COUNT(P.Id) AS TotalPosts,
    SUM(P.ViewCount) AS TotalViews,
    AVG(P.Score) AS AverageScore,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
    COUNT(DISTINCT C.Id) AS TotalComments
FROM 
    Posts P
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
GROUP BY 
    PT.Name
ORDER BY 
    TotalPosts DESC;