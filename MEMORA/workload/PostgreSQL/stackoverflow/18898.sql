SELECT COUNT(*) AS TotalPosts,
       SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
       SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
       AVG(ViewCount) AS AverageViews
FROM Posts;
