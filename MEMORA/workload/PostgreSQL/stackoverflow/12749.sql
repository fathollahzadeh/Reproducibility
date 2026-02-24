WITH PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        U.Reputation AS OwnerReputation,
        COUNT(V.Id) AS VoteCount,
        MAX(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        MAX(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'  
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount, P.CommentCount, U.Reputation
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostsCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    PM.PostId,
    PM.Title, 
    PM.CreationDate,
    PM.Score,
    PM.ViewCount,
    PM.AnswerCount,
    PM.CommentCount,
    PM.OwnerReputation,
    PM.VoteCount,
    PM.Upvotes,
    PM.Downvotes,
    UA.UserId,
    UA.DisplayName,
    UA.PostsCount,
    UA.QuestionsCount,
    UA.AnswersCount,
    UA.TotalViews
FROM 
    PostMetrics PM
JOIN 
    UserActivity UA ON PM.OwnerReputation = UA.UserId
ORDER BY 
    PM.ViewCount DESC, PM.Score DESC
LIMIT 100;