WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(V.BountyAmount) AS TotalBounties,
        AVG(U.Reputation) AS AverageReputation
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        U.Id, U.DisplayName
),
PostScore AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        (P.Score + COALESCE(P.FavoriteCount, 0) * 2) AS AdjustedScore,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY (P.Score + COALESCE(P.FavoriteCount, 0) * 2) DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
)
SELECT 
    UA.DisplayName,
    UA.PostCount,
    UA.QuestionCount,
    UA.AnswerCount,
    UA.TotalBounties,
    UA.AverageReputation,
    PS.Title,
    PS.AdjustedScore,
    PS.Rank
FROM 
    UserActivity UA
LEFT JOIN 
    PostScore PS ON UA.UserId = PS.PostId
WHERE 
    UA.PostCount > 5
    AND PS.Rank <= 10
ORDER BY 
    UA.AverageReputation DESC, PS.AdjustedScore DESC;