WITH TagStats AS (
    SELECT
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM
        Tags T
    JOIN
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    WHERE
        P.PostTypeId = 1 
    GROUP BY
        T.TagName
),
UserStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionsAnswered,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(CASE WHEN P.Score > 0 THEN P.Score ELSE 0 END) AS TotalPositiveScore,
        AVG(P.Score) AS AverageScore
    FROM
        Users U
    JOIN
        Posts P ON U.Id = P.OwnerUserId
    WHERE
        P.PostTypeId = 2 
    GROUP BY
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        QuestionsAnswered,
        AcceptedAnswers,
        TotalPositiveScore,
        AverageScore,
        RANK() OVER (ORDER BY TotalPositiveScore DESC) AS ScoreRank
    FROM
        UserStats
),
RankedTags AS (
    SELECT
        TagName,
        PostCount,
        TotalViews,
        AverageScore,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM
        TagStats
)
SELECT
    U.DisplayName AS TopUser,
    U.QuestionsAnswered,
    U.AcceptedAnswers,
    U.TotalPositiveScore,
    T.TagName AS PopularTag,
    T.PostCount,
    T.TotalViews,
    T.AverageScore
FROM
    TopUsers U
JOIN
    RankedTags T ON T.ViewRank <= 5 
WHERE
    U.ScoreRank <= 10 
ORDER BY
    U.TotalPositiveScore DESC, 
    T.TotalViews DESC;