
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COALESCE(UP.TotalVotes, 0) AS TotalVotes,
        COALESCE(UP.Upvotes, 0) AS Upvotes,
        COALESCE(UP.Downvotes, 0) AS Downvotes,
        PS.CommentCount,
        PS.VoteCount
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        UserVoteStats UP ON U.Id = UP.UserId
    JOIN 
        PostStats PS ON P.Id = PS.PostId
)
SELECT 
    UserId,
    DisplayName,
    COUNT(PostId) AS TotalPosts,
    SUM(ViewCount) AS TotalPostViews,
    AVG(Score) AS AvgPostScore,
    SUM(CommentCount) AS TotalComments,
    SUM(VoteCount) AS TotalVotes
FROM 
    UserPostStats
GROUP BY 
    UserId,
    DisplayName
ORDER BY 
    TotalPosts DESC, 
    TotalPostViews DESC;
