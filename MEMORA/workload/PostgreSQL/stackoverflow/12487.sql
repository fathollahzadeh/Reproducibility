WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT A.Id) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Posts A ON A.ParentId = P.Id AND P.PostTypeId = 1 AND A.PostTypeId = 2
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
TopQuestions AS (
    SELECT 
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.Score,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalAnswers,
    U.TotalViews,
    TQ.Title AS TopQuestion,
    TQ.Score
FROM 
    UserStats U
LEFT JOIN 
    TopQuestions TQ ON U.UserId = TQ.OwnerUserId AND TQ.Rank = 1
ORDER BY 
    U.Reputation DESC
LIMIT 10;