WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN P.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedPosts,
        SUM(COALESCE(CommentCounts.CommentCount, 0)) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT 
            C.PostId,
            COUNT(C.Id) AS CommentCount
        FROM 
            Comments C
        GROUP BY 
            C.PostId
    ) AS CommentCounts ON P.Id = CommentCounts.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        PositiveScorePosts,
        ClosedPosts,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    TU.Rank,
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers,
    TU.PositiveScorePosts,
    TU.ClosedPosts,
    B.Name AS BadgeName,
    B.Class AS BadgeClass
FROM 
    TopUsers TU
LEFT JOIN 
    Badges B ON TU.UserId = B.UserId
WHERE 
    TU.Rank <= 10
ORDER BY 
    TU.Rank, B.Class DESC;
