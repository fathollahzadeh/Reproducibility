
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.Reputation
)
SELECT 
    UserId,
    Reputation,
    PostCount,
    CommentCount,
    VoteCount,
    (PostCount + CommentCount + VoteCount) AS TotalActivity
FROM 
    UserPostStats
ORDER BY 
    TotalActivity DESC;
