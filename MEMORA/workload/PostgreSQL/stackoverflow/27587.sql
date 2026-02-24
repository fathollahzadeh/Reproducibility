
WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag,
        PostTypeId,
        Id AS PostId,
        OwnerUserId
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
),
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(*) AS QuestionCount,
        COUNT(DISTINCT OwnerUserId) AS UserCount
    FROM 
        TagCounts
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        QuestionCount,
        UserCount,
        ROW_NUMBER() OVER (ORDER BY QuestionCount DESC, UserCount DESC) AS Rank
    FROM 
        TagStatistics
    WHERE 
        QuestionCount > 10 
),
UserTagEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        T.Tag,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    JOIN 
        TagCounts T ON P.Id = T.PostId
    GROUP BY 
        U.Id, U.DisplayName, T.Tag
),
EngagementRankings AS (
    SELECT 
        UserId, 
        DisplayName, 
        Tag, 
        PostCount,
        QuestionCount,
        AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY Tag ORDER BY PostCount DESC) AS TagRank
    FROM 
        UserTagEngagement
)

SELECT 
    E.Tag, 
    E.DisplayName, 
    E.PostCount,
    E.QuestionCount,
    E.AnswerCount,
    T.QuestionCount AS TotalQuestionsForTag,
    T.UserCount AS TotalUsersForTag,
    CASE 
        WHEN E.TagRank <= 5 THEN 'Top Contributor'
        ELSE 'Contributor'
    END AS ContributionLevel
FROM 
    EngagementRankings E
JOIN 
    TopTags T ON E.Tag = T.Tag
WHERE 
    E.TagRank <= 10 
ORDER BY 
    E.Tag, E.PostCount DESC;
