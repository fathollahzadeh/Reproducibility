WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        SUM(CASE 
                WHEN V.VoteTypeId = 2 THEN 1 
                ELSE 0 
            END) AS UpVoteCount,
        SUM(CASE 
                WHEN V.VoteTypeId = 3 THEN 1 
                ELSE 0 
            END) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title
)

SELECT 
    U.UserId,
    U.Reputation,
    U.TotalPosts,
    U.TotalComments,
    U.TotalBounty,
    P.PostId,
    P.Title,
    P.CommentCount,
    P.VoteCount,
    P.UpVoteCount,
    P.DownVoteCount
FROM 
    UserStats U
JOIN 
    PostStats P ON U.UserId = P.PostId
ORDER BY 
    U.Reputation DESC, U.TotalPosts DESC;