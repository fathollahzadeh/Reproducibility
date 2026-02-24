
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COUNT(DISTINCT PH.Id) AS EditHistoryCount,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.CreationDate
),
TopUsers AS (
    SELECT 
        UR.DisplayName,
        UR.Reputation,
        UR.UserId,
        RANK() OVER (ORDER BY UR.Reputation DESC) AS OverallRank
    FROM 
        UserReputation UR
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS RecentPostDate,
    RP.CommentCount,
    RP.EditHistoryCount,
    (SELECT COUNT(*) 
     FROM Votes V 
     WHERE V.UserId = TU.UserId AND V.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 month') AS RecentVotes
FROM 
    TopUsers TU
JOIN 
    RecentPosts RP ON RP.PostRank = 1
WHERE 
    TU.OverallRank <= 10
ORDER BY 
    TU.Reputation DESC, RP.CommentCount DESC;
