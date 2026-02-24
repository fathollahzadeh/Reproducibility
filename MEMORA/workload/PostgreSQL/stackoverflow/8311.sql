
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
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
        CommentCount,
        Upvotes,
        Downvotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStats
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.PostCount,
    T.CommentCount,
    T.Upvotes,
    T.Downvotes,
    T.ReputationRank,
    P.Title,
    P.CreationDate,
    PH.CreationDate AS LastEditDate,
    PH.Comment AS EditComment
FROM 
    TopUsers T
JOIN 
    Posts P ON T.UserId = P.OwnerUserId
JOIN 
    PostHistory PH ON PH.PostId = P.Id
WHERE 
    T.ReputationRank <= 10
    AND P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
    AND PH.PostHistoryTypeId IN (4, 5) 
ORDER BY 
    T.Reputation DESC, 
    P.CreationDate DESC;
