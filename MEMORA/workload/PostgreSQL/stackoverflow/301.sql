WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        U.Views,
        (U.UpVotes - U.DownVotes) AS NetVotes
    FROM Users U
    WHERE U.Reputation > 100
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.NetVotes,
        COUNT(P.PostId) AS PostCount,
        SUM(P.ViewCount) AS TotalViews
    FROM UserScores U
    JOIN RecentPosts P ON U.UserId = P.OwnerUserId
    GROUP BY U.UserId, U.DisplayName, U.Reputation, U.NetVotes
    HAVING COUNT(P.PostId) >= 5 AND SUM(P.ViewCount) >= 1000
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.NetVotes,
    T.PostCount,
    T.TotalViews,
    STRING_AGG(CASE WHEN R.PostRank <= 3 THEN R.Title END, ', ') AS RecentTopThreePosts
FROM TopUsers T
LEFT JOIN RecentPosts R ON T.UserId = R.OwnerUserId
GROUP BY T.DisplayName, T.Reputation, T.NetVotes, T.PostCount, T.TotalViews
ORDER BY T.Reputation DESC, T.NetVotes DESC;