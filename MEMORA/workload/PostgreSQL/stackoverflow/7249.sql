WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikis,
        SUM(CASE WHEN P.LastActivityDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN 1 ELSE 0 END) AS RecentActivity,
        MAX(P.LastActivityDate) AS LastActiveDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.Reputation, U.CreationDate
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        Questions,
        Answers,
        Wikis,
        RecentActivity,
        LastActiveDate,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStats
)
SELECT 
    T.UserId,
    U.DisplayName,
    T.Reputation,
    T.PostCount,
    T.Questions,
    T.Answers,
    T.Wikis,
    T.RecentActivity,
    T.LastActiveDate,
    RANK() OVER (PARTITION BY T.ReputationRank ORDER BY T.Reputation DESC) AS RankInGroup
FROM 
    TopUsers T
JOIN 
    Users U ON T.UserId = U.Id
WHERE 
    T.ReputationRank <= 10
ORDER BY 
    T.Reputation DESC, RankInGroup;