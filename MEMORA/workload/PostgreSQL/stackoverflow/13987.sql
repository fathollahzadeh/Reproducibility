WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(C.Id, 0)) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.Reputation, U.CreationDate
),
PostTypesStats AS (
    SELECT 
        PT.Name AS PostType,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.AnswerCount) AS TotalAnswers
    FROM 
        PostTypes PT
    LEFT JOIN 
        Posts P ON PT.Id = P.PostTypeId
    GROUP BY 
        PT.Name
)

SELECT 
    U.UserId,
    U.Reputation,
    U.CreationDate,
    U.BadgeCount,
    U.PostCount,
    U.TotalScore,
    U.TotalViews,
    U.TotalAnswers,
    U.CommentCount,
    PT.PostType,
    PT.TotalPosts,
    PT.TotalScore AS PostTypeTotalScore,
    PT.TotalViews AS PostTypeTotalViews,
    PT.TotalAnswers AS PostTypeTotalAnswers
FROM 
    UserStats U
CROSS JOIN 
    PostTypesStats PT
ORDER BY 
    U.Reputation DESC, PT.TotalPosts DESC;