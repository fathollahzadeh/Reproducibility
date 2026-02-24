WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.Score IS NOT NULL THEN P.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT UserId, DisplayName, Reputation, PostCount, TotalScore, BadgeCount
    FROM UserStatistics
    WHERE Rank <= 10
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.TotalScore,
    TU.BadgeCount,
    COALESCE(PH.Comment, 'No Comments') AS LastPostComment,
    CASE 
        WHEN U.LastAccessDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' THEN 'Inactive'
        ELSE 'Active'
    END AS UserStatus
FROM TopUsers TU
LEFT JOIN Posts P ON TU.UserId = P.OwnerUserId
LEFT JOIN Comments C ON P.Id = C.PostId
LEFT JOIN PostHistory PH ON PH.PostId = P.Id AND PH.CreationDate = (
    SELECT MAX(CreationDate) 
    FROM PostHistory 
    WHERE PostId = P.Id
)
JOIN Users U ON TU.UserId = U.Id
WHERE TU.PostCount > 5
ORDER BY TU.Reputation DESC, TU.TotalScore DESC
LIMIT 20;