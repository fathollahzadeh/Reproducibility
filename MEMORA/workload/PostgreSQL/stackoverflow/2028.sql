WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation
),
TopUsers AS (
    SELECT 
        UR.UserId,
        UR.Reputation,
        UR.PostCount,
        RANK() OVER (ORDER BY UR.Reputation DESC) AS UserRank
    FROM 
        UserReputation UR
)
SELECT 
    TU.UserId,
    U.DisplayName,
    TU.Reputation,
    TU.PostCount,
    RP.Title,
    RP.CreationDate,
    RP.Score
FROM 
    TopUsers TU
JOIN 
    Users U ON TU.UserId = U.Id
LEFT JOIN 
    RankedPosts RP ON TU.UserId = RP.OwnerUserId AND RP.PostRank = 1
WHERE 
    TU.UserRank <= 10
ORDER BY 
    TU.Reputation DESC;