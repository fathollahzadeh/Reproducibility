SELECT
    U.DisplayName,
    COUNT(P.Id) AS TotalPosts,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    AVG(P.Score) AS AverageScore
FROM
    Users U
LEFT JOIN
    Posts P ON U.Id = P.OwnerUserId
GROUP BY
    U.DisplayName
ORDER BY
    TotalPosts DESC
LIMIT 10;
