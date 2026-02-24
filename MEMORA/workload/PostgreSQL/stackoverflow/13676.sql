
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,  
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount 
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.OwnerUserId
),

UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT V.Id) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId 
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    U.DisplayName AS PostOwner,
    PS.CommentCount,
    PS.UpVoteCount,
    PS.DownVoteCount,
    UA.TotalPosts,
    UA.TotalComments,
    UA.TotalVotes
FROM 
    PostStats PS
JOIN 
    Users U ON PS.OwnerUserId = U.Id
JOIN 
    UserActivity UA ON U.Id = UA.UserId
ORDER BY 
    PS.CreationDate DESC
LIMIT 100;
