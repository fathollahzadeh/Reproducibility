
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
AggregatedStats AS (
    SELECT 
        AVG(Reputation) AS AvgReputation,
        AVG(PostCount) AS AvgPostCount,
        AVG(UpVotes) AS AvgUpVotes,
        AVG(DownVotes) AS AvgDownVotes
    FROM 
        UserStats
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.UpVotes,
    U.DownVotes,
    A.AvgReputation,
    A.AvgPostCount,
    A.AvgUpVotes,
    A.AvgDownVotes
FROM 
    UserStats U, AggregatedStats A
WHERE 
    U.Reputation > 1000  
ORDER BY 
    U.Reputation DESC;
