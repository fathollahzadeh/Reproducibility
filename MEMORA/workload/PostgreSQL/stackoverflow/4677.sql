
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(DISTINCT P.Id), 0) AS PostCount,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UpVotes,
        DownVotes,
        PostCount,
        Rank
    FROM 
        UserStats
    WHERE 
        Reputation > 1000
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.UpVotes,
    TU.DownVotes,
    TU.PostCount,
    (SELECT COUNT(*) FROM Comments C WHERE C.UserId = TU.UserId) AS CommentCount,
    (SELECT STRING_AGG(T.TagName, ', ') 
     FROM Tags T 
     JOIN Posts P ON T.Id = P.Id 
     WHERE P.OwnerUserId = TU.UserId) AS AssociatedTags
FROM 
    TopUsers TU
LEFT JOIN 
    Badges B ON TU.UserId = B.UserId
WHERE 
    B.Class = 1 OR B.Class = 2  
ORDER BY 
    TU.Reputation DESC
FETCH FIRST 10 ROWS ONLY;
