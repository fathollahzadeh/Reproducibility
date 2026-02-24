WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties,
        SUM(COALESCE(C.Score, 0)) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName
), 
PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        P.CreationDate,
        P.LastActivityDate,
        ARRAY_AGG(DISTINCT T.TagName) AS Tags
    FROM 
        Posts P
    LEFT JOIN 
        unnest(string_to_array(P.Tags, '<>')) AS Tag ON TRUE
    JOIN 
        Tags T ON T.TagName = Tag
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.AnswerCount, P.CommentCount, P.FavoriteCount, P.CreationDate, P.LastActivityDate
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalBounties,
    U.TotalComments,
    P.PostId,
    P.Title AS PostTitle,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.FavoriteCount,
    P.CreationDate,
    P.LastActivityDate,
    P.Tags
FROM 
    UserStats U
JOIN 
    PostEngagement P ON U.UserId = P.PostId
ORDER BY 
    U.TotalPosts DESC, P.ViewCount DESC
LIMIT 100;