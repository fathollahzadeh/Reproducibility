
WITH RecursiveTags AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Tags,
        unnest(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><')) AS TagName,
        P.CreationDate
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1
),
TagCounts AS (
    SELECT 
        TagName,
        COUNT(PostId) AS PostCount,
        MIN(CreationDate) AS FirstUsage
    FROM 
        RecursiveTags
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount,
        FirstUsage
    FROM 
        TagCounts
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId IN (1, 2)
    GROUP BY 
        U.Id, U.DisplayName
),
UserTopContributors AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        PositiveScoreCount
    FROM 
        UserPostCounts
    WHERE 
        PostCount > 0
    ORDER BY 
        PositiveScoreCount DESC
    LIMIT 5
),
FinalOutput AS (
    SELECT 
        T.TagName,
        T.PostCount AS TagPostCount,
        U.DisplayName AS TopUser,
        U.PositiveScoreCount AS TopUserScores
    FROM 
        TopTags T
    JOIN 
        UserTopContributors U ON U.PostCount > T.PostCount
)
SELECT 
    TagName, 
    TagPostCount, 
    TopUser, 
    TopUserScores
FROM 
    FinalOutput
ORDER BY 
    TagPostCount DESC, 
    TopUserScores DESC;
