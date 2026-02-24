
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(P.ViewCount) AS TotalViews
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.OwnerUserId
),
UserWithPosts AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        PS.PostCount,
        PS.UpVotes,
        PS.DownVotes,
        PS.TotalViews
    FROM UserReputation UR
    LEFT JOIN PostStats PS ON UR.UserId = PS.OwnerUserId
)
SELECT 
    UWP.UserId,
    UWP.DisplayName,
    UWP.Reputation,
    COALESCE(UWP.PostCount, 0) AS TotalPosts,
    COALESCE(UWP.UpVotes, 0) AS TotalUpVotes,
    COALESCE(UWP.DownVotes, 0) AS TotalDownVotes,
    UWP.TotalViews,
    (COALESCE(UWP.UpVotes, 0) - COALESCE(UWP.DownVotes, 0)) AS NetVotes,
    CASE 
        WHEN UWP.Reputation >= 1000 THEN 'High Reputation'
        WHEN UWP.Reputation >= 500 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM UserWithPosts UWP
WHERE UWP.TotalViews >= 1000
AND UWP.UserId IS NOT NULL
ORDER BY UWP.Reputation DESC
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
