SELECT 
    U.Id AS UserId,
    U.DisplayName,
    AVG(P.Score) AS AvgScore,
    SUM(P.AnswerCount) AS TotalAnswers,
    SUM(P.ViewCount) AS TotalViews
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
WHERE 
    P.PostTypeId = 1 
    AND B.Id IS NOT NULL 
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    TotalViews DESC
LIMIT 10;