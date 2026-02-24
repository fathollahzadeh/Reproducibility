WITH UserVotes AS (
    SELECT 
        U.Id AS UserId, 
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes, 
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
), 
PostStats AS (
    SELECT 
        P.Id AS PostId, 
        P.OwnerUserId, 
        P.Title, 
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount, 
        COUNT(CASE WHEN PH.Id IS NOT NULL THEN 1 END) AS EditHistoryCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId 
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.OwnerUserId, P.Title
), 
PostOwnerStats AS (
    SELECT 
        P.OwnerUserId, 
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN PS.EditHistoryCount > 0 THEN 1 END) AS PostsWithEditHistory,
        SUM(CASE WHEN PS.CommentCount > 5 THEN 1 ELSE 0 END) AS PopularPosts
    FROM 
        PostStats PS
    JOIN 
        Posts P ON PS.PostId = P.Id
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    U.DisplayName, 
    U.Reputation, 
    COALESCE(UP.Upvotes, 0) AS UserUpvotes, 
    COALESCE(UP.Downvotes, 0) AS UserDownvotes,
    POS.TotalPosts, 
    POS.PostsWithEditHistory,
    POS.PopularPosts
FROM 
    Users U
LEFT JOIN 
    UserVotes UP ON U.Id = UP.UserId
LEFT JOIN 
    PostOwnerStats POS ON U.Id = POS.OwnerUserId
WHERE 
    U.Reputation > 500
ORDER BY 
    U.Reputation DESC, 
    UserUpvotes DESC;