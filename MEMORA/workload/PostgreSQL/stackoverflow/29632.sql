
WITH TagCount AS (
    SELECT
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM
        Posts
    WHERE
        PostTypeId = 1 
    GROUP BY
        Tag
),
UserParticipation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS OwnedQuestions,
        SUM(CASE WHEN ph.PostId IS NOT NULL THEN 1 ELSE 0 END) AS EditedQuestions
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5) 
    GROUP BY
        u.Id, u.DisplayName
),
TopParticipants AS (
    SELECT
        UserId,
        DisplayName,
        QuestionCount,
        OwnedQuestions,
        EditedQuestions,
        RANK() OVER (ORDER BY QuestionCount DESC) AS Rank
    FROM
        UserParticipation
    WHERE
        QuestionCount > 0
),
TopTags AS (
    SELECT
        Tag,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM
        TagCount
)
SELECT
    tp.Rank AS TagRank,
    tp.Tag AS PopularTag,
    tp.PostCount AS TagPostCount,
    t.UserId,
    t.DisplayName AS Contributor,
    t.QuestionCount AS UserQuestionCount,
    t.OwnedQuestions,
    t.EditedQuestions
FROM
    TopParticipants t
JOIN
    TopTags tp ON tp.Rank <= 5 
ORDER BY
    tp.Rank, t.Rank;
