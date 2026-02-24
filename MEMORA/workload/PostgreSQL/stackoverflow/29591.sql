WITH TagStats AS (
    SELECT 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TagName
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS QuestionCount,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount,
        SUM(CASE WHEN P.ViewCount IS NOT NULL THEN P.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN P.Score IS NOT NULL THEN P.Score ELSE 0 END) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStats
    WHERE 
        PostCount > 5  
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        AcceptedAnswerCount,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY QuestionCount DESC, TotalScore DESC) AS UserRank
    FROM 
        UserPostStats
)
SELECT 
    TU.DisplayName AS TopUser,
    TU.QuestionCount,
    TU.AcceptedAnswerCount,
    TU.TotalViews,
    TU.TotalScore,
    TT.TagName AS PopularTag,
    TT.PostCount
FROM 
    TopUsers TU
JOIN 
    TopTags TT ON TU.QuestionCount > 10  
WHERE 
    TU.UserRank <= 10 AND TT.TagRank <= 20  
ORDER BY 
    TU.TotalScore DESC, TU.AcceptedAnswerCount DESC;