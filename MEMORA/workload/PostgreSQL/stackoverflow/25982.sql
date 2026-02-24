
WITH TagUsage AS (
    SELECT
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) AS TagName,
        COUNT(*) AS PostsCount
    FROM
        Posts
    WHERE
        PostTypeId = 1 
    GROUP BY
        TagName
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT
        TagName,
        PostsCount,
        ROW_NUMBER() OVER (ORDER BY PostsCount DESC) AS Rnk
    FROM
        TagUsage
    WHERE
        PostsCount > 5
),
ActiveUsers AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS Rnk
    FROM
        UserActivity
    WHERE
        TotalPosts > 10
)
SELECT
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.UpVotesReceived,
    u.DownVotesReceived,
    t.TagName,
    t.PostsCount
FROM
    ActiveUsers u
JOIN
    TopTags t ON t.Rnk <= 5 
ORDER BY
    u.TotalPosts DESC,
    t.PostsCount DESC;
