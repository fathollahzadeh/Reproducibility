WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN P.PostTypeId = 2 THEN P.Score ELSE 0 END) AS TotalAnswerScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        EXTRACT(YEAR FROM P.CreationDate) AS PostYear,
        PT.Name AS PostTypeName,
        COALESCE(COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END), 0) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8  
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, PT.Name
),
UserPostActivity AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.PostCount,
        UA.QuestionCount,
        UA.AnswerCount,
        UA.TotalViews,
        UA.TotalAnswerScore,
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.Score,
        PS.ViewCount,
        PS.PostYear,
        PS.PostTypeName,
        PS.CommentCount,
        PS.TotalBounty
    FROM 
        UserActivity UA
    JOIN 
        PostStatistics PS ON UA.UserId = PS.PostId
)
SELECT 
    U.DisplayName,
    UP.PostId,
    UP.Title,
    UP.CreationDate,
    UP.Score,
    UP.ViewCount,
    UP.PostTypeName,
    UP.CommentCount,
    UP.TotalBounty,
    UP.TotalViews,
    UP.QuestionCount,
    UP.AnswerCount,
    RANK() OVER (ORDER BY UP.TotalViews DESC) AS ViewRank
FROM 
    UserPostActivity UP
JOIN 
    Users U ON UP.UserId = U.Id
WHERE 
    UP.PostCount > 5
ORDER BY 
    UP.TotalViews DESC, UP.CreationDate ASC;