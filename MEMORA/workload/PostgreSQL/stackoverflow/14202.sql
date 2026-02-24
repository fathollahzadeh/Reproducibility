
WITH UsersAnalytics AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
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
        U.Id, U.Reputation
), 
PostsAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        P.PostTypeId,
        P.AcceptedAnswerId,
        U.DisplayName AS OwnerDisplayName,
        CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END AS HasAcceptedAnswer,
        P.OwnerUserId
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
)
SELECT 
    UA.UserId,
    UA.Reputation,
    UA.TotalPosts,
    UA.TotalComments,
    UA.TotalUpVotes,
    UA.TotalDownVotes,
    PA.PostId,
    PA.Title,
    PA.CreationDate,
    PA.ViewCount,
    PA.Score,
    PA.AnswerCount,
    PA.CommentCount,
    PA.FavoriteCount,
    PA.OwnerDisplayName,
    PA.HasAcceptedAnswer
FROM 
    UsersAnalytics UA
JOIN 
    PostsAnalytics PA ON UA.UserId = PA.OwnerUserId
ORDER BY 
    UA.Reputation DESC, PA.ViewCount DESC
LIMIT 100;
