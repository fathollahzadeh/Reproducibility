WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        COALESCE(COUNT(DISTINCT P.Id), 0) AS TotalPosts,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS TotalClosures,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 24 THEN 1 ELSE 0 END), 0) AS TotalEdits
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
AggregatedData AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalViews,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalClosures,
        TotalEdits,
        RANK() OVER (ORDER BY TotalViews DESC, Reputation DESC) AS ViewRank,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserActivity
),
MostActiveUsers AS (
    SELECT 
        *, 
        GREATEST(ViewRank, PostRank) AS CombinedRank
    FROM 
        AggregatedData
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    TotalViews,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalClosures,
    TotalEdits,
    CombinedRank
FROM 
    MostActiveUsers
WHERE 
    CombinedRank <= 10
ORDER BY 
    CombinedRank;

