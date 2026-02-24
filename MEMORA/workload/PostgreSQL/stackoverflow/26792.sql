
WITH TagStatistics AS (
    SELECT
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) AS TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM
        Posts
    WHERE
        Tags IS NOT NULL
    GROUP BY
        TagName
),
PopularTags AS (
    SELECT
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM
        TagStatistics
    WHERE
        PostCount > 10
),
ActiveUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM
        Users u
    JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        u.Reputation > 1000
    GROUP BY
        u.Id, u.DisplayName
),
UserTagSummary AS (
    SELECT
        u.UserId,
        u.DisplayName,
        t.TagName,
        t.PostCount,
        CASE
            WHEN u.AnswerCount > 0 THEN ROUND((t.PostCount * 1.0 / u.AnswerCount * 1.0) * 100, 2)
            ELSE 0
        END AS TagEngagement
    FROM
        ActiveUsers u
    JOIN
        (SELECT
            OwnerUserId,
            TRIM(UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) AS TagName,
            COUNT(*) AS PostCount
         FROM
            Posts
         WHERE
            Tags IS NOT NULL
         GROUP BY
            OwnerUserId, TagName) t ON u.UserId = t.OwnerUserId
)
SELECT
    u.DisplayName AS UserName,
    u.TagName,
    u.TagEngagement,
    COUNT(DISTINCT p.Id) AS ContributionCount,
    MAX(p.CreationDate) AS LastContributionDate
FROM
    UserTagSummary u
JOIN
    Posts p ON u.UserId = p.OwnerUserId AND p.Tags LIKE '%' || u.TagName || '%'
GROUP BY
    u.DisplayName, u.TagName, u.TagEngagement
ORDER BY
    u.TagEngagement DESC, ContributionCount DESC
LIMIT 20;
