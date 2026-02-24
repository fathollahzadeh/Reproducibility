SELECT 
    COUNT(P.Id) AS TotalPosts,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    AVG(CASE WHEN P.PostTypeId = 1 THEN P.Score END) AS AverageQuestionScore,
    AVG(CASE WHEN P.PostTypeId = 2 THEN P.Score END) AS AverageAnswerScore,
    COUNT(DISTINCT U.Id) AS TotalUsers,
    COUNT(DISTINCT T.Id) AS TotalTags,
    SUM(V.BountyAmount) AS TotalBountyAmount
FROM 
    Posts P
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Tags T ON P.Tags LIKE CONCAT('%', T.TagName, '%')  
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'  
GROUP BY 
    DATE(P.CreationDate)  
ORDER BY 
    DATE(P.CreationDate) ASC;