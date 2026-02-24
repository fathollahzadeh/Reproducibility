
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(P.Score), 0) AS TotalScore,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
), 
PostHistoryStats AS (
    SELECT 
        PH.UserId, 
        COUNT(PH.Id) AS TotalEdits,
        COUNT(DISTINCT PH.Comment) AS UniqueEditComments,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    GROUP BY 
        PH.UserId
), 
Summary AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.TotalPosts,
        US.TotalQuestions,
        US.TotalAnswers,
        US.TotalScore,
        US.TotalViews,
        US.TotalComments,
        COALESCE(PHS.TotalEdits, 0) AS TotalEdits,
        COALESCE(PHS.UniqueEditComments, 0) AS UniqueEditComments,
        PHS.LastEditDate
    FROM 
        UserStats US
    LEFT JOIN PostHistoryStats PHS ON US.UserId = PHS.UserId
)
SELECT 
    DisplayName,
    Reputation,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalScore,
    TotalViews,
    TotalComments,
    TotalEdits,
    UniqueEditComments,
    LastEditDate
FROM 
    Summary
ORDER BY 
    TotalScore DESC, 
    Reputation DESC
LIMIT 10;
