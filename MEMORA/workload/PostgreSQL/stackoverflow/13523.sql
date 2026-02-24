WITH Benchmark AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(V.BountyAmount) AS TotalBountyAmount,
        AVG(P.Score) AS AveragePostScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.Reputation
)

SELECT 
    UserId,
    Reputation,
    PostCount,
    CommentCount,
    BadgeCount,
    TotalBountyAmount,
    AveragePostScore
FROM 
    Benchmark
ORDER BY 
    Reputation DESC, PostCount DESC;
