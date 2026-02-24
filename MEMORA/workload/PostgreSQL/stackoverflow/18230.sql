SELECT 
    U.DisplayName, 
    COUNT(P.Id) AS PostCount, 
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount, 
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount 
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.DisplayName
ORDER BY 
    PostCount DESC
LIMIT 10;
