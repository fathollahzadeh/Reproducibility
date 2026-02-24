
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank,
        P.OwnerUserId
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        UR.PostCount,
        UR.UpVoteCount,
        UR.DownVoteCount
    FROM 
        UserReputation UR
    WHERE 
        UR.Reputation > 1000 AND UR.PostCount > 5
    ORDER BY 
        UR.Reputation DESC
    LIMIT 10
)
SELECT 
    TU.DisplayName, 
    TU.Reputation,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS RecentPostDate,
    (TU.UpVoteCount - TU.DownVoteCount) AS VoteBalance
FROM 
    TopUsers TU
LEFT JOIN 
    RecentPosts RP ON TU.UserId = RP.OwnerUserId AND RP.PostRank = 1
WHERE 
    TU.Reputation IS NOT NULL
ORDER BY 
    VoteBalance DESC, TU.Reputation DESC;
