WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        COUNT(C.Id) AS TotalComments,
        COUNT(V.Id) AS TotalVotes,
        MAX(P.LastActivityDate) AS LastPostActivityDate
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
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        P.OwnerUserId,
        P.LastActivityDate
    FROM 
        Posts P
    WHERE 
        P.LastActivityDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.TotalPosts,
    UPS.TotalComments,
    UPS.TotalVotes,
    UPS.LastPostActivityDate,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.AnswerCount,
    PS.CommentCount,
    PS.FavoriteCount
FROM 
    UserPostStats UPS
LEFT JOIN 
    PostStats PS ON UPS.UserId = PS.OwnerUserId
ORDER BY 
    UPS.TotalPosts DESC
LIMIT 100;