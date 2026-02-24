
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
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
        ReputationRank
    FROM 
        UserStats
    WHERE 
        ReputationRank <= 10
),
MostActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(COALESCE(CM.Id, 0)) AS CommentCount,
        COUNT(DISTINCT V.UserId) AS VoteCount,
        MAX(P.CreationDate) AS LastActivity
    FROM 
        Posts P
    LEFT JOIN 
        Comments CM ON P.Id = CM.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title
    ORDER BY 
        VoteCount DESC
    LIMIT 5
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    A.PostId,
    A.Title,
    A.CommentCount,
    A.VoteCount,
    A.LastActivity
FROM 
    TopUsers TU
JOIN 
    MostActivePosts A ON A.CommentCount >= 5
ORDER BY 
    TU.Reputation DESC;
