WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViewCount,
        SUM(P.Score) AS TotalScore,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        U.Reputation > 0  
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.TotalPosts,
    UPS.TotalQuestions,
    UPS.TotalAnswers,
    UPS.TotalViewCount,
    UPS.TotalScore,
    UPS.TotalComments,
    RANK() OVER (ORDER BY UPS.TotalScore DESC) AS ScoreRank,
    RANK() OVER (ORDER BY UPS.TotalViewCount DESC) AS ViewCountRank
FROM 
    UserPostStats UPS
ORDER BY 
    UPS.TotalScore DESC, UPS.TotalPosts DESC;