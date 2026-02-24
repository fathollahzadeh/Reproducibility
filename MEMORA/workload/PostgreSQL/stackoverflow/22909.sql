WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - U.CreationDate)) / 3600) AS AvgAccountAgeHours
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
RecentPostHistory AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        COUNT(*) OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate) AS EditCount,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS RecentEditRank
    FROM PostHistory PH
    WHERE PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
UserRecentActivity AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        SUM(CASE WHEN RPH.EditCount > 1 AND RPH.PostHistoryTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TotalEdits,
        SUM(CASE WHEN RPH.RecentEditRank = 1 THEN 1 ELSE 0 END) AS NewlyEditedPosts
    FROM UserStatistics US
    LEFT JOIN RecentPostHistory RPH ON US.UserId = RPH.UserId
    GROUP BY US.UserId, US.DisplayName, US.Reputation
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    COALESCE(RA.TotalEdits, 0) AS TotalEdits,
    COALESCE(RA.NewlyEditedPosts, 0) AS NewlyEditedPosts,
    CASE 
        WHEN U.AvgAccountAgeHours > 0 THEN ROUND(U.Reputation / U.AvgAccountAgeHours, 2)
        ELSE NULL 
    END AS ReputationPerHour,
    (SELECT STRING_AGG(B.Name, ', ') 
     FROM Badges B 
     WHERE B.UserId = U.UserId 
     AND B.Class = 1) AS GoldBadges
FROM UserStatistics U
LEFT JOIN UserRecentActivity RA ON U.UserId = RA.UserId
ORDER BY U.Reputation DESC, U.TotalPosts DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;