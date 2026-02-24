
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN VB.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN VB.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Votes VB ON U.Id = VB.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),

PostScore AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Score,
        P.CreationDate,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
)

SELECT 
    U.DisplayName,
    U.Reputation,
    U.UpVotes,
    U.DownVotes,
    U.PostCount,
    PS.PostId,
    PS.Score,
    PS.CreationDate,
    PS.ScoreRank
FROM 
    UserStats U
JOIN 
    PostScore PS ON U.UserId = PS.OwnerUserId
WHERE 
    (U.UpVotes - U.DownVotes) >= 10
    AND PS.ScoreRank = 1
    AND PS.CreationDate IS NOT NULL
ORDER BY 
    U.Reputation DESC, PS.Score DESC
LIMIT 50;
