WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        MAX(P.CreationDate) AS LastPostDate,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionsCount,
        AnswersCount,
        LastPostDate,
        ReputationRank
    FROM UserStatistics
    WHERE Reputation > 1000
),
RecentPostHistory AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.CreationDate,
        P.Title,
        P.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY PH.UserId ORDER BY PH.CreationDate DESC) AS RecentAction
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.QuestionsCount,
    TU.AnswersCount,
    TU.LastPostDate,
    COALESCE(RPH.Title, 'No Recent Activity') AS RecentPostTitle,
    RPH.CreationDate AS RecentActionDate,
    CASE 
        WHEN TU.ReputationRank <= 10 THEN 'Top Contributor'
        WHEN TU.ReputationRank <= 50 THEN 'Active Contributor'
        ELSE 'New Contributor' 
    END AS ContributorLevel
FROM TopUsers TU
LEFT JOIN RecentPostHistory RPH ON TU.UserId = RPH.UserId AND RPH.RecentAction = 1
ORDER BY TU.Reputation DESC, TU.DisplayName ASC;