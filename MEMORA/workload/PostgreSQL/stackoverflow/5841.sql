
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        AVG(COALESCE(P.Score, 0)) AS AvgScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        AnswerCount,
        QuestionCount,
        AvgScore,
        TotalViews,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, PostCount DESC, AvgScore DESC) AS Rnk
    FROM 
        UserStats
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        UNNEST(STRING_TO_ARRAY(P.Tags, '<>')) AS Tag
    FROM 
        Posts P
    WHERE 
        P.Tags IS NOT NULL
),
TagStats AS (
    SELECT 
        T.Tag AS TagName,
        COUNT(DISTINCT T.PostId) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM 
        PostTags T
    JOIN 
        Posts P ON T.PostId = P.Id
    GROUP BY 
        T.Tag
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, TotalViews DESC) AS Rnk
    FROM 
        TagStats
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    U.PostCount,
    U.AnswerCount,
    U.QuestionCount,
    U.AvgScore,
    U.TotalViews,
    T.TagName,
    T.PostCount AS TagPostCount,
    T.TotalViews AS TagTotalViews
FROM 
    TopUsers U
JOIN 
    TopTags T ON U.Rnk <= 10 AND T.Rnk <= 10
ORDER BY 
    U.Reputation DESC, U.PostCount DESC, T.PostCount DESC;
