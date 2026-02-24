
WITH TagStats AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts
    GROUP BY 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><'))
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PopularTags AS (
    SELECT 
        TS.Tag,
        TS.PostCount,
        US.DisplayName,
        US.TotalPosts,
        RANK() OVER (ORDER BY TS.PostCount DESC) AS TagRank
    FROM 
        TagStats TS
    JOIN 
        Posts P ON P.Tags LIKE '%' || TS.Tag || '%'
    JOIN 
        UserStats US ON P.OwnerUserId = US.UserId
    WHERE 
        TS.PostCount > 10
)
SELECT 
    PT.Tag,
    PT.PostCount,
    PT.DisplayName,
    PT.TotalPosts,
    US.TotalScore,
    PT.TagRank
FROM 
    PopularTags PT
JOIN 
    UserStats US ON PT.DisplayName = US.DisplayName
WHERE 
    PT.TagRank <= 5
ORDER BY 
    PT.TagRank;
