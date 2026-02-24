
WITH TagDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Tags,
        t.TagName,
        COUNT(*) AS TagUsageCount
    FROM
        Posts p
    INNER JOIN
        Tags t ON t.TagName = ANY(string_to_array(TRIM(BOTH '{}' FROM p.Tags), '><'))
    WHERE
        p.PostTypeId = 1 
    GROUP BY
        p.Id, p.Title, p.Tags, t.TagName
),
TopTags AS (
    SELECT
        TagName,
        SUM(TagUsageCount) AS TotalUsage
    FROM
        TagDetails
    GROUP BY
        TagName
    ORDER BY
        TotalUsage DESC
    LIMIT 10
),
UserScore AS (
    SELECT
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT p.Id) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgPostScore
    FROM
        Users u
    LEFT JOIN
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 2 
    LEFT JOIN
        Votes v ON v.PostId = p.Id
    GROUP BY
        u.Id
),
TopUsers AS (
    SELECT
        DisplayName,
        Upvotes, 
        Downvotes, 
        AnswerCount,
        TotalViews,
        AvgPostScore
    FROM
        UserScore
    ORDER BY 
        Upvotes DESC, 
        AnswerCount DESC 
    LIMIT 5
)
SELECT
    tt.TagName,
    tt.TotalUsage,
    tu.DisplayName,
    tu.Upvotes,
    tu.Downvotes,
    tu.AnswerCount,
    tu.TotalViews,
    tu.AvgPostScore
FROM
    TopTags tt
JOIN 
    TopUsers tu ON EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.OwnerDisplayName = tu.DisplayName 
        AND (p.Tags ILIKE '%' || tt.TagName || '%')
    )
ORDER BY 
    tt.TotalUsage DESC, 
    tu.Upvotes DESC;
