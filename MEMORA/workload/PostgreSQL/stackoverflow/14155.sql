WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(COUNT(CM.Id), 0) AS CommentCount,
        COALESCE(V.Score, 0) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments CM ON P.Id = CM.PostId
    LEFT JOIN 
        (SELECT 
             PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE -1 END) AS Score
         FROM 
             Votes 
         GROUP BY 
             PostId) V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, V.Score
)
SELECT 
    US.UserId,
    US.TotalPosts,
    US.TotalQuestions,
    US.TotalAnswers,
    US.TotalScore,
    US.TotalViews,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.CommentCount,
    PS.TotalVotes
FROM 
    UserStats US
JOIN 
    PostSummary PS ON PS.TotalVotes > 10
ORDER BY 
    US.TotalScore DESC, PS.ViewCount DESC
LIMIT 100;