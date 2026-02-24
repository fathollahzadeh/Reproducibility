WITH TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
    WHERE U.Reputation > 1000
),
PostAggregates AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(P.Score) AS AvgScore
    FROM Posts P 
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY P.OwnerUserId
),
RecentPostHistory AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS RecentChange
    FROM PostHistory PH
    WHERE PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    U.DisplayName,
    U.Reputation,
    PA.TotalPosts,
    PA.Questions,
    PA.Answers,
    PA.AvgScore,
    SUM(CASE WHEN RPH.RecentChange = 1 THEN 1 ELSE 0 END) AS RecentChangesCount,
    PT.Name AS PostTypeName,
    COALESCE(CRT.Name, 'Not Closed') AS ClosureReason
FROM TopUsers U
JOIN PostAggregates PA ON U.Id = PA.OwnerUserId
LEFT JOIN RecentPostHistory RPH ON U.Id = RPH.UserId
LEFT JOIN Posts P ON RPH.PostId = P.Id
LEFT JOIN PostTypes PT ON P.PostTypeId = PT.Id
LEFT JOIN PostHistory PH ON PH.PostId = P.Id AND PH.PostHistoryTypeId = 10
LEFT JOIN CloseReasonTypes CRT ON CAST(PH.Comment AS INTEGER) = CRT.Id
WHERE U.Reputation > 1000
GROUP BY U.DisplayName, U.Reputation, PA.TotalPosts, PA.Questions, PA.Answers, PA.AvgScore, PT.Name, CRT.Name
ORDER BY U.Reputation DESC
FETCH FIRST 10 ROWS ONLY;