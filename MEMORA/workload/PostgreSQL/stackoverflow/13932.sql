WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS TotalUpvotedPosts,
        AVG(P.Score) AS AverageScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
TopActiveUsers AS (
    SELECT 
        UserId,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalUpvotedPosts,
        AverageScore,
        LastPostDate,
        RANK() OVER (ORDER BY TotalPosts DESC) AS UserRank
    FROM 
        UserPostStats
)
SELECT 
    U.DisplayName,
    U.Reputation,
    TA.TotalPosts,
    TA.TotalQuestions,
    TA.TotalAnswers,
    TA.TotalUpvotedPosts,
    TA.AverageScore,
    TA.LastPostDate
FROM 
    TopActiveUsers TA
JOIN 
    Users U ON TA.UserId = U.Id
WHERE 
    TA.UserRank <= 10
ORDER BY 
    TA.UserRank;