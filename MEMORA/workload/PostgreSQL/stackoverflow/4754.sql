
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.AcceptedAnswerId,
        COALESCE(PA.OwnerDisplayName, 'No accepted answer') AS AcceptedAnswerOwner,
        P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN 
        Posts PA ON P.AcceptedAnswerId = PA.Id
    WHERE 
        P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
),
PostStats AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        UA.Views,
        COUNT(DISTINCT PD.PostId) AS PostsInLastYear,
        AVG(PD.Score) AS AveragePostScore,
        SUM(PD.ViewCount) AS TotalPostViews,
        SUM(PD.AnswerCount) AS TotalAnswers,
        STRING_AGG(DISTINCT PD.AcceptedAnswerOwner, ', ') AS AcceptedAnswerOwners
    FROM 
        UserActivity UA
    JOIN 
        PostDetails PD ON UA.UserId = PD.OwnerUserId
    GROUP BY 
        UA.UserId, UA.DisplayName, UA.Reputation, UA.Views
)
SELECT 
    U.Id,
    U.DisplayName,
    U.Reputation,
    COALESCE(PS.PostsInLastYear, 0) AS PostsInLastYear,
    COALESCE(PS.AveragePostScore, 0) AS AveragePostScore,
    COALESCE(PS.TotalPostViews, 0) AS TotalPostViews,
    COALESCE(PS.TotalAnswers, 0) AS TotalAnswers,
    PS.AcceptedAnswerOwners
FROM 
    Users U
LEFT JOIN 
    PostStats PS ON U.Id = PS.UserId
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.Reputation DESC, 
    PS.TotalPostViews DESC
LIMIT 
    50;
