
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        UpVotes,
        DownVotes,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserReputation
    WHERE 
        Reputation > 1000
)

SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.UpVotes,
    TU.DownVotes,
    (TU.UpVotes - TU.DownVotes) AS NetVotes
FROM 
    TopUsers TU
WHERE 
    TU.Rank <= 10
ORDER BY 
    TU.Reputation DESC, NetVotes DESC;
