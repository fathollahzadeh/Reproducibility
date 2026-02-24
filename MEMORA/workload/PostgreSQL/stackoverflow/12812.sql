WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBountyAmount
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
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AverageViewCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.PostTypeId
)
SELECT 
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.CommentCount,
    U.TotalBountyAmount,
    P.PostId,
    P.PostTypeId,
    P.CommentCount AS PostCommentCount,
    P.VoteCount,
    P.TotalScore,
    P.AverageViewCount
FROM 
    UserStats U
JOIN 
    PostStats P ON U.UserId = P.PostId
ORDER BY 
    U.Reputation DESC, P.TotalScore DESC;