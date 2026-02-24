
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COALESCE(COUNT(DISTINCT P.Id), 0) AS TotalPosts,
        COALESCE(COUNT(DISTINCT C.Id), 0) AS TotalComments,
        COALESCE(MAX(P.CreationDate), '1970-01-01') AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
RecentActivity AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS RecentPosts,
        COUNT(C.Id) AS RecentComments,
        COUNT(DISTINCT PH.Id) AS PostHistoryChanges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    LEFT JOIN 
        Comments C ON U.Id = C.UserId AND C.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    LEFT JOIN 
        PostHistory PH ON U.Id = PH.UserId AND PH.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    GROUP BY 
        U.Id
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalUpVotes,
    US.TotalDownVotes,
    US.TotalPosts,
    US.TotalComments,
    US.LastPostDate,
    RA.RecentPosts,
    RA.RecentComments,
    RA.PostHistoryChanges
FROM 
    UserStats US
JOIN 
    RecentActivity RA ON US.UserId = RA.UserId
WHERE 
    US.Reputation > 100
ORDER BY 
    US.Reputation DESC, 
    RA.RecentPosts DESC;
