WITH QuestionTags AS (
    SELECT
        Posts.Id AS QuestionId,
        Posts.Title AS QuestionTitle,
        Posts.CreationDate AS QuestionCreationDate,
        Posts.Tags,
        UNNEST(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')) AS Tag
    FROM
        Posts
    WHERE
        Posts.PostTypeId = 1
),
TagStatistics AS (
    SELECT
        Tag,
        COUNT(*) AS TagCount,
        MIN(QuestionCreationDate) AS FirstUsed,
        MAX(QuestionCreationDate) AS MostRecentUsed
    FROM
        QuestionTags
    GROUP BY
        Tag
),
TopTags AS (
    SELECT
        Tag,
        TagCount,
        FirstUsed,
        MostRecentUsed,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM
        TagStatistics
    WHERE
        TagCount > 5  
)

SELECT
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    TT.Tag,
    TT.TagCount,
    TT.FirstUsed,
    TT.MostRecentUsed
FROM
    Users U
JOIN
    Posts P ON U.Id = P.OwnerUserId
JOIN
    TopTags TT ON TT.Tag = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><'))
WHERE
    P.PostTypeId = 1  
ORDER BY
    TT.TagCount DESC,
    U.Reputation DESC
LIMIT 10;