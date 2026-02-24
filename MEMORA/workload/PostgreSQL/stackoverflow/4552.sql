WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        (COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) - COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0)) AS Score,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
HighScoreUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation,
        Score,
        RANK() OVER (ORDER BY Score DESC) AS Rank
    FROM 
        UserScores
    WHERE 
        Score > 0
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score AS PostScore,
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.Score > 0
    GROUP BY 
        P.Id, P.Title, P.Score, P.OwnerUserId
)
SELECT 
    U.DisplayName AS User,
    U.Reputation,
    HS.Score AS UserScore,
    TP.Title AS TopPost,
    TP.PostScore,
    TP.CommentCount
FROM 
    HighScoreUsers HS
JOIN 
    Users U ON HS.UserId = U.Id
LEFT JOIN 
    TopPosts TP ON U.Id = TP.OwnerUserId AND TP.Rank = 1
WHERE 
    HS.Rank <= 10
ORDER BY 
    HS.Score DESC, U.Reputation DESC;
