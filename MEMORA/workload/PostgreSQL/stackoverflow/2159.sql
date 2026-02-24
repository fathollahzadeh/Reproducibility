WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.Score) AS TotalScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        LastPostDate,
        RANK() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        UserPostStats
),
PostHistoryCount AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS HistoryCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.UserId
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers,
    TU.TotalScore,
    TU.LastPostDate,
    COALESCE(PHC.HistoryCount, 0) AS HistoryCount,
    CASE 
        WHEN TU.TotalPosts > 50 THEN 'Veteran'
        WHEN TU.TotalPosts BETWEEN 20 AND 50 THEN 'Active'
        ELSE 'Newcomer'
    END AS UserCategory
FROM 
    TopUsers TU
LEFT JOIN 
    PostHistoryCount PHC ON TU.UserId = PHC.UserId
WHERE 
    TU.Rank <= 10
ORDER BY 
    TU.TotalScore DESC;
