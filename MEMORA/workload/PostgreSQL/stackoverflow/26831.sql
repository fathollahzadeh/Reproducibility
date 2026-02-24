
WITH PostTags AS (
    SELECT
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1
),
PopularTags AS (
    SELECT
        Tag,
        COUNT(*) AS TagCount
    FROM
        PostTags
    GROUP BY
        Tag
    HAVING
        COUNT(*) > 10  
),
RecentUserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.LastActivityDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' THEN 1 ELSE 0 END) AS RecentActivityCount,
        AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate))) AS AvgPostAge
    FROM
        Users u
        JOIN Posts p ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1
    GROUP BY
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        QuestionCount,
        RecentActivityCount,
        AvgPostAge,
        RANK() OVER (ORDER BY QuestionCount DESC) AS UserRank
    FROM
        RecentUserActivity
    WHERE
        RecentActivityCount > 0
)
SELECT
    t.Tag,
    t.TagCount,
    tu.DisplayName,
    tu.QuestionCount,
    tu.RecentActivityCount,
    tu.AvgPostAge
FROM
    PopularTags t
JOIN
    TopUsers tu ON tu.QuestionCount > 5  
ORDER BY
    t.TagCount DESC, tu.QuestionCount DESC
LIMIT 10;
