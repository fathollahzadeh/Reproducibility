WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        QuestionsCount,
        AnswersCount,
        TotalScore,
        TotalViews,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserStatistics
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS UsedCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.Id, T.TagName
    ORDER BY 
        UsedCount DESC
    LIMIT 10
)
SELECT 
    U.DisplayName AS TopUser,
    U.Reputation,
    U.TotalPosts,
    U.QuestionsCount,
    U.AnswersCount,
    U.TotalScore,
    U.TotalViews,
    T.TagName AS PopularTag,
    T.UsedCount
FROM 
    TopUsers U
CROSS JOIN 
    PopularTags T
WHERE 
    U.ScoreRank <= 10;
