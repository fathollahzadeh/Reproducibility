WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
), 
PostHistoryStats AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS TotalEdits,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (24, 10, 11) THEN 1 ELSE 0 END) AS TotalSignificantEdits
    FROM PostHistory PH
    GROUP BY PH.UserId
), 
RankedUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.TotalPosts,
        UA.TotalQuestions,
        UA.TotalAnswers,
        UA.PopularPosts,
        COALESCE(PHS.TotalEdits, 0) AS TotalEdits,
        COALESCE(PHS.TotalSignificantEdits, 0) AS TotalSignificantEdits,
        ROW_NUMBER() OVER (ORDER BY UA.TotalPosts DESC, UA.TotalQuestions DESC) AS Rank
    FROM UserActivity UA
    LEFT JOIN PostHistoryStats PHS ON UA.UserId = PHS.UserId
)
SELECT 
    RU.DisplayName,
    RU.TotalPosts,
    RU.TotalQuestions,
    RU.TotalAnswers,
    RU.PopularPosts,
    RU.TotalEdits,
    RU.TotalSignificantEdits,
    (CASE 
        WHEN RU.TotalAnswers > 5 THEN 'Frequent Answerer'
        WHEN RU.TotalQuestions > 5 THEN 'Active Questioner'
        ELSE 'Novice User' 
    END) AS UserType
FROM RankedUsers RU
WHERE RU.Rank <= 10
ORDER BY RU.Rank;
