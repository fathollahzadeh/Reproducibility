WITH RankedUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
TopPostCounts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY P.OwnerUserId
),
RecentVotes AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes V
    WHERE V.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY V.UserId
),
UserStats AS (
    SELECT 
        RU.Id AS UserId,
        RU.DisplayName,
        COALESCE(TPC.PostCount, 0) AS PostCount,
        COALESCE(RV.VoteCount, 0) AS VoteCount,
        COALESCE(RV.UpVotes, 0) AS UpVotes,
        COALESCE(RV.DownVotes, 0) AS DownVotes,
        RU.ReputationRank
    FROM RankedUsers RU
    LEFT JOIN TopPostCounts TPC ON RU.Id = TPC.OwnerUserId
    LEFT JOIN RecentVotes RV ON RU.Id = RV.UserId
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.ReputationRank,
    US.PostCount,
    US.VoteCount,
    (US.UpVotes - US.DownVotes) AS NetVotes,
    CASE 
        WHEN US.ReputationRank <= 10 THEN 'Top Contributor'
        WHEN US.ReputationRank BETWEEN 11 AND 50 THEN 'Moderate Contributor'
        ELSE 'New Contributor'
    END AS ContributorType
FROM UserStats US
WHERE US.PostCount > 0
ORDER BY US.ReputationRank
LIMIT 100;