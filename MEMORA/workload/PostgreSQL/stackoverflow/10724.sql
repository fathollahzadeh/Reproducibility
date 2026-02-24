
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(P.Id) AS TotalPosts,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
    SUM(COALESCE(C.CommentCount, 0)) AS TotalComments,
    AVG(COALESCE(P.Score, 0)) AS AveragePostScore,
    SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) C ON P.Id = C.PostId
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    TotalPosts DESC, AveragePostScore DESC
FETCH FIRST 100 ROWS ONLY;
