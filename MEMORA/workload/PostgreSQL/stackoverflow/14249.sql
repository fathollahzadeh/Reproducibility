
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUserPosts AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.TotalPosts,
        U.TotalQuestions,
        U.TotalAnswers,
        U.TotalScore,
        U.TotalViews,
        ROW_NUMBER() OVER (ORDER BY U.TotalScore DESC) AS Rank
    FROM 
        UserPostStats U
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalScore,
    TotalViews,
    Rank
FROM 
    TopUserPosts
WHERE 
    Rank <= 10;
