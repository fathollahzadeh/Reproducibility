
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostAggregate AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COALESCE(PH.TotalHistoryChanges, 0) AS HistoryChanges,
        COALESCE(CR.ReasonName, 'N/A') AS CloseReason
    FROM Posts P
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS TotalHistoryChanges
        FROM PostHistory
        GROUP BY PostId
    ) PH ON P.Id = PH.PostId
    LEFT JOIN (
        SELECT PH.PostId, CRT.Name AS ReasonName
        FROM PostHistory PH
        JOIN CloseReasonTypes CRT ON CAST(PH.Comment AS INTEGER) = CRT.Id
        WHERE PH.PostHistoryTypeId IN (10, 11) 
        GROUP BY PH.PostId, CRT.Name
    ) CR ON P.Id = CR.PostId
),
UserPostDetails AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        SUM(PA.ViewCount) AS TotalPostViews,
        SUM(PA.Score) AS TotalPostScore,
        AVG(PA.HistoryChanges) AS AvgPostHistoryChanges,
        ARRAY_AGG(DISTINCT PA.CloseReason) AS CloseReasons
    FROM UserStatistics US
    JOIN PostAggregate PA ON US.UserId = PA.PostId
    GROUP BY US.UserId, US.DisplayName
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalUpvotes,
    U.TotalDownvotes,
    UPD.TotalPostViews,
    UPD.TotalPostScore,
    UPD.AvgPostHistoryChanges,
    UNNEST(UPD.CloseReasons) AS CloseReason 
FROM UserStatistics U
JOIN UserPostDetails UPD ON U.UserId = UPD.UserId
ORDER BY U.Reputation DESC, U.TotalPosts DESC
LIMIT 100;
