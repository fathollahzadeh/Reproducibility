
WITH TagFrequency AS (
    SELECT 
        TRIM(UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '><'))) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS Rank
    FROM 
        TagFrequency
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000 
    GROUP BY 
        U.Id, U.DisplayName
),
TopActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalViews,
        QuestionCount,
        AnswerCount,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS UserRank
    FROM 
        ActiveUsers
)

SELECT 
    TT.Tag,
    TT.TagCount,
    TA.DisplayName AS TopUser,
    TA.TotalViews,
    TA.QuestionCount,
    TA.AnswerCount
FROM 
    TopTags TT
JOIN 
    TopActiveUsers TA ON TA.QuestionCount > 0 
WHERE 
    TT.Rank <= 10 
ORDER BY 
    TT.TagCount DESC, TA.TotalViews DESC;
