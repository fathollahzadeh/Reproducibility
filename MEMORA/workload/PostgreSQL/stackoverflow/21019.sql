
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        TotalScore,
        AvgViewCount,
        LastPostDate,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserPostStats
    WHERE 
        LastPostDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 month')
)
SELECT 
    U.DisplayName,
    U.TotalPosts,
    U.QuestionCount,
    U.AnswerCount,
    COALESCE(CASE 
        WHEN U.AnswerCount = 0 THEN 'No Answers' 
        ELSE CAST(U.AnswerCount AS VARCHAR)
    END, 'N/A') AS AnswerStatus,
    U.TotalScore,
    U.AvgViewCount,
    U.ScoreRank,
    A.TagsUsed,
    A.BadgesEarned
FROM 
    ActiveUsers U
LEFT JOIN (
    SELECT 
        U.Id AS UserId,
        STRING_AGG(DISTINCT T.TagName, ', ') AS TagsUsed,
        COUNT(DISTINCT B.Id) AS BadgesEarned
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Tags T ON POSITION(T.TagName IN P.Tags) > 0
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
) A ON U.UserId = A.UserId
WHERE 
    U.TotalPosts > 0 
    AND U.ScoreRank <= 10
ORDER BY 
    U.TotalScore DESC, 
    U.LastPostDate DESC
LIMIT 50;
