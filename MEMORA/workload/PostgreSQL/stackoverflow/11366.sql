WITH BenchmarkResults AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(CAST(ViewCount AS FLOAT)) AS AverageViews,
        AVG(CAST(Score AS FLOAT)) AS AverageScore,
        COUNT(DISTINCT OwnerUserId) AS UniqueUsers,
        COUNT(DISTINCT CASE WHEN PostTypeId = 1 THEN Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN PostTypeId = 2 THEN Id END) AS TotalAnswers
    FROM 
        Posts
)
SELECT 
    *,
    (SELECT COUNT(*) FROM Comments) AS TotalComments,
    (SELECT COUNT(*) FROM Votes) AS TotalVotes
FROM 
    BenchmarkResults;
