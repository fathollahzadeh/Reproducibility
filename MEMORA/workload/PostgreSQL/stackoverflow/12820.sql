WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.Reputation
),
PostTypesCount AS (
    SELECT 
        PT.Id AS PostTypeId,
        PT.Name AS PostTypeName,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.Score) AS TotalScore
    FROM 
        PostTypes PT
    LEFT JOIN 
        Posts P ON PT.Id = P.PostTypeId
    GROUP BY 
        PT.Id, PT.Name
)
SELECT 
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.AnswerCount,
    U.QuestionCount,
    U.CommentCount,
    PT.PostTypeId,
    PT.PostTypeName,
    PT.TotalPosts,
    PT.TotalScore
FROM 
    UserStats U
CROSS JOIN 
    PostTypesCount PT
ORDER BY 
    U.Reputation DESC, PT.TotalPosts DESC
LIMIT 100;