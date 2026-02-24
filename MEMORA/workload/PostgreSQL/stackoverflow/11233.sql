WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(V.Id, 0)) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        Reputation, 
        PostCount, 
        TotalScore, 
        TotalVotes,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        UserReputation
)
SELECT 
    U.DisplayName,
    U.Reputation,
    TU.PostCount,
    TU.TotalScore,
    TU.TotalVotes
FROM 
    TopUsers TU
INNER JOIN 
    Users U ON TU.UserId = U.Id
WHERE 
    TU.Rank <= 10;