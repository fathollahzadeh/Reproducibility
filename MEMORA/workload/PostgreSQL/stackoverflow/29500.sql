
WITH TagCounts AS (
    SELECT
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM
        Posts
    WHERE
        PostTypeId = 1 
    GROUP BY
        TagName
),
TopTags AS (
    SELECT
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM
        TagCounts
    WHERE
        PostCount > 10 
),
UserScores AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionsAnswered,
        COUNT(DISTINCT c.Id) AS CommentsMade
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 2 
    LEFT JOIN
        Comments c ON u.Id = c.UserId
    GROUP BY
        u.Id, u.Reputation
),
HighScoringUsers AS (
    SELECT
        UserId,
        Reputation,
        QuestionsAnswered,
        CommentsMade,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM
        UserScores
    WHERE
        Reputation > 1000 
)
SELECT
    t.TagName,
    t.PostCount,
    u.UserId,
    u.Reputation,
    u.QuestionsAnswered,
    u.CommentsMade
FROM
    TopTags t
JOIN
    HighScoringUsers u ON EXISTS (
        SELECT 1
        FROM Posts p
        WHERE p.Title LIKE '%' || t.TagName || '%'
        AND p.OwnerUserId = u.UserId
    )
ORDER BY
    t.PostCount DESC, u.Reputation DESC
LIMIT 20;
