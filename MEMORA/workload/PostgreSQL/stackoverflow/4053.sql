WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM Posts P
    GROUP BY P.OwnerUserId
),
TopUsers AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        PS.TotalPosts,
        PS.TotalQuestions,
        PS.TotalAnswers
    FROM UserReputation UR
    JOIN PostStats PS ON UR.UserId = PS.OwnerUserId
    WHERE UR.Reputation > 1000
)
SELECT 
    COALESCE(TU.DisplayName, 'Unknown User') AS UserName,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers,
    COALESCE(PHT.Name, 'No History') AS RecentActionType,
    COUNT(PH.Id) AS ActionCount
FROM TopUsers TU
LEFT JOIN PostHistory PH ON PH.UserId = TU.UserId AND PH.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
LEFT JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
GROUP BY TU.UserId, TU.DisplayName, TU.Reputation, TU.TotalPosts, TU.TotalQuestions, TU.TotalAnswers, PHT.Name
ORDER BY TU.Reputation DESC, ActionCount DESC
LIMIT 10;