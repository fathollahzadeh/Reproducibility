SELECT 
    U.DisplayName,
    COUNT(P.Id) AS PostCount,
    SUM(CASE WHEN PT.Name = 'Answer' THEN 1 ELSE 0 END) AS AnswerCount,
    SUM(CASE WHEN PT.Name = 'Question' THEN 1 ELSE 0 END) AS QuestionCount
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
GROUP BY 
    U.DisplayName
ORDER BY 
    PostCount DESC
LIMIT 10;
