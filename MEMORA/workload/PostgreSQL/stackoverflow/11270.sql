WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistoryStats AS (
    SELECT 
        P.Id AS PostId,
        COUNT(PH.Id) AS TotalHistoryRecords,
        MAX(PH.CreationDate) AS LastEditedDate
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.TotalPosts,
    UPS.TotalQuestions,
    UPS.TotalAnswers,
    UPS.TotalScore,
    UPS.AvgViewCount,
    PHS.TotalHistoryRecords,
    PHS.LastEditedDate
FROM 
    UserPostStats UPS
LEFT JOIN 
    PostHistoryStats PHS ON UPS.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = PHS.PostId LIMIT 1)
ORDER BY 
    UPS.TotalScore DESC,
    UPS.TotalPosts DESC;