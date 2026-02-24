
WITH TagUsage AS (
    SELECT
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
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
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM
        TagUsage
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN
        Comments c ON u.Id = c.UserId
    LEFT JOIN
        Votes v ON u.Id = v.UserId AND v.PostId IN (SELECT Id FROM Posts WHERE PostTypeId = 1)
    GROUP BY
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        QuestionsAsked,
        CommentsMade,
        UpvotesReceived,
        ROW_NUMBER() OVER (ORDER BY UpvotesReceived DESC) AS Rank
    FROM
        UserActivity
    WHERE
        QuestionsAsked > 0
)
SELECT
    tg.TagName,
    tg.PostCount AS NumberOfQuestions,
    tu.DisplayName AS TopUser,
    tu.QuestionsAsked,
    tu.CommentsMade,
    tu.UpvotesReceived
FROM
    TopTags tg
JOIN
    TopUsers tu ON tg.Rank = tu.Rank
WHERE
    tg.Rank <= 10
ORDER BY
    tg.PostCount DESC, tu.UpvotesReceived DESC;
