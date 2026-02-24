WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COUNT(CASE WHEN P.Score > 0 THEN 1 END) AS PositiveScorePosts,
        COUNT(CASE WHEN P.Score < 0 THEN 1 END) AS NegativeScorePosts,
        AVG(P.ViewCount) AS AvgViewCount,
        AVG(P.AnswerCount) AS AvgAnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        PositiveScorePosts,
        NegativeScorePosts,
        AvgViewCount,
        AvgAnswerCount,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY PositiveScorePosts DESC) AS PosScoreRank
    FROM 
        UserPostStats
    WHERE 
        TotalPosts > 0
)

SELECT 
    U.DisplayName,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.PositiveScorePosts,
    U.NegativeScorePosts,
    U.AvgViewCount,
    U.AvgAnswerCount,
    PHT.Name AS PostHistoryType,
    PH.CreationDate AS HistoryDate,
    PH.Comment
FROM 
    TopUsers U
LEFT JOIN 
    Posts P ON U.UserId = P.OwnerUserId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
LEFT JOIN 
    PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
WHERE 
    U.PostRank <= 10 OR U.PosScoreRank <= 10
ORDER BY 
    U.PostRank, U.PosScoreRank;