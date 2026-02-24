
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(DISTINCT P.Id) AS PostCount,
    SUM(P.ViewCount) AS TotalViews,
    SUM(CASE WHEN V.UserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotes,
    SUM(CASE WHEN P.PostTypeId = 1 THEN P.AnswerCount ELSE 0 END) AS TotalAnswers,
    SUM(CASE WHEN P.PostTypeId = 1 THEN P.CommentCount ELSE 0 END) AS TotalComments,
    AVG(P.Score) AS AvgPostScore,
    MAX(P.CreationDate) AS LastPostDate
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
GROUP BY 
    U.Id, U.DisplayName
HAVING 
    COUNT(DISTINCT P.Id) > 0
ORDER BY 
    TotalViews DESC;
