
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation,
        U.CreationDate,
        DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS Ranking
    FROM 
        Users U
), RecentPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.OwnerUserId, 
        P.Title, 
        P.CreationDate, 
        P.Score, 
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.OwnerUserId, P.Title, P.CreationDate, P.Score
), TopUsers AS (
    SELECT 
        UR.UserId, 
        UR.DisplayName, 
        UR.Reputation
    FROM 
        UserReputation UR
    WHERE 
        UR.Ranking <= 10
)
SELECT 
    T.DisplayName AS TopUser, 
    RP.Title AS RecentPostTitle, 
    RP.Score AS PostScore, 
    RP.CommentCount,
    COALESCE( (
        SELECT 
            STRING_AGG(DISTINCT C.Text, ', ') 
        FROM 
            Comments C 
        WHERE 
            C.PostId = RP.PostId
    ), 'No comments') AS RecentComments
FROM 
    RecentPosts RP
JOIN 
    TopUsers T ON RP.OwnerUserId = T.UserId
LEFT JOIN 
    Votes V ON RP.PostId = V.PostId AND V.VoteTypeId = 2
WHERE 
    RP.Score > 10
ORDER BY 
    RP.CreationDate DESC
LIMIT 100;
