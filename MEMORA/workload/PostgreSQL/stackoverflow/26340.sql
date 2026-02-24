WITH TagWordCounts AS (
    SELECT
        t.TagName,
        COUNT(*) AS TagCount,
        SUM(LENGTH(p.Body) - LENGTH(REPLACE(p.Body, t.TagName, ''))) / LENGTH(t.TagName) AS WordOccurrence
    FROM
        Tags t
    JOIN
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY
        t.TagName
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS DownvotedPosts
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id, u.Reputation
),
PopularTags AS (
    SELECT
        TagName,
        TagCount,
        WordOccurrence,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM
        TagWordCounts
)
SELECT
    u.UserId,
    u.Reputation,
    u.PostsCount,
    u.UpvotedPosts,
    u.DownvotedPosts,
    pt.TagName,
    pt.TagCount,
    pt.WordOccurrence
FROM
    UserReputation u
JOIN
    PopularTags pt ON u.PostsCount > 10 AND u.Reputation > 1000
WHERE
    pt.TagRank <= 10
ORDER BY
    u.Reputation DESC, pt.TagCount DESC;