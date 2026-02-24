
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.CreationDate,
        T.TagName,
        P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN 
        Tags T ON P.Tags LIKE CONCAT('%', T.TagName, '%')
),
VoteStats AS (
    SELECT
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.TotalComments,
    U.TotalUpVotes,
    U.TotalDownVotes,
    P.PostId,
    P.Title,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.CreationDate,
    V.UpVotes,
    V.DownVotes,
    STRING_AGG(DISTINCT P.TagName, ', ') AS Tags
FROM 
    UserStats U
JOIN 
    PostStats P ON U.UserId = P.OwnerUserId
JOIN 
    VoteStats V ON P.PostId = V.PostId
GROUP BY 
    U.UserId, U.DisplayName, U.TotalPosts, U.TotalComments, U.TotalUpVotes, U.TotalDownVotes, 
    P.PostId, P.Title, P.Score, P.ViewCount, P.AnswerCount, P.CommentCount, P.CreationDate, V.UpVotes, V.DownVotes
ORDER BY 
    U.TotalPosts DESC, P.ViewCount DESC
LIMIT 100;
