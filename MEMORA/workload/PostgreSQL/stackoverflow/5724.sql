WITH UserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        SUM(CASE WHEN V.VoteTypeId IN (6, 7) THEN 1 ELSE 0 END) AS CloseReopenVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN H.Id IS NOT NULL THEN 1 END) AS EditCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        MAX(P.CreationDate) AS LastActivityDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory H ON P.Id = H.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CommentCount,
        PS.EditCount,
        PS.TotalUpvotes - PS.TotalDownvotes AS NetScore,
        RANK() OVER (ORDER BY PS.TotalUpvotes DESC) AS Rank
    FROM 
        PostStats PS
)
SELECT 
    UP.UserId,
    UP.DisplayName,
    TP.Title,
    TP.CommentCount,
    TP.EditCount,
    TP.NetScore
FROM 
    UserVotes UP
JOIN 
    TopPosts TP ON UP.Upvotes > 0
WHERE 
    TP.Rank <= 10
ORDER BY 
    UP.Upvotes DESC, TP.NetScore DESC;
