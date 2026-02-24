SELECT 
    P.Title AS QuestionTitle,
    P.CreationDate AS QuestionDate,
    P.ViewCount AS NumberOfViews,
    P.Score AS QuestionScore,
    A.CreationDate AS AnswerDate,
    EXTRACT(EPOCH FROM (A.CreationDate - P.CreationDate)) AS ResponseTimeInSeconds,
    A.Score AS AnswerScore,
    U.DisplayName AS AnswererDisplayName
FROM 
    Posts P
JOIN 
    Posts A ON P.Id = A.ParentId
JOIN 
    Users U ON A.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1 
    AND A.PostTypeId = 2 
ORDER BY 
    ResponseTimeInSeconds;