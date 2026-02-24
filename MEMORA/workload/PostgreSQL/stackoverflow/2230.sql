
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        C.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON CAST(PH.Comment AS INTEGER) = C.Id
    WHERE 
        PH.PostHistoryTypeId = 10
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalViews,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStats
),
TopUsers AS (
    SELECT 
        * 
    FROM 
        RankedUsers 
    WHERE 
        ReputationRank <= 10
)
SELECT 
    T.DisplayName,
    T.TotalQuestions,
    T.TotalAnswers,
    T.TotalViews,
    COALESCE(CP.CloseReason, 'No Closure') AS RecentCloseReason,
    (SELECT COUNT(*) FROM Comments C WHERE C.UserId = T.UserId) AS TotalComments
FROM 
    TopUsers T
LEFT JOIN 
    ClosedPosts CP ON T.UserId = CP.UserId
WHERE 
    T.TotalPosts > 5
ORDER BY 
    T.Reputation DESC, 
    T.DisplayName;
