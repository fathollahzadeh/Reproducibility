
WITH UserAggregate AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties,
        AVG(COALESCE(P.Score, 0)) AS AverageScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId 
    GROUP BY 
        U.Id
),
PostAggregate AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        P.ViewCount,
        P.Score,
        COALESCE(COUNT(C.Id), 0) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.LastActivityDate, P.ViewCount, P.Score
),
TopUsers AS (
    SELECT 
        UA.UserId, 
        UA.PostCount, 
        UA.QuestionCount, 
        UA.AnswerCount, 
        UA.TotalBounties, 
        UA.AverageScore
    FROM 
        UserAggregate UA
    ORDER BY 
        UA.PostCount DESC
    LIMIT 10
)
SELECT 
    TU.UserId,
    TU.PostCount,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.TotalBounties,
    TU.AverageScore,
    PA.Title,
    PA.CreationDate,
    PA.LastActivityDate,
    PA.ViewCount,
    PA.Score,
    PA.CommentCount
FROM 
    TopUsers TU
JOIN 
    Posts P ON TU.UserId = P.OwnerUserId
JOIN 
    PostAggregate PA ON P.Id = PA.PostId
ORDER BY 
    TU.TotalBounties DESC, TU.AverageScore DESC;
