
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
    FROM Posts p
    WHERE p.PostTypeId = 1  
),
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(*) AS QuestionCount,
        ARRAY_AGG(DISTINCT p.Title) AS ExampleTitles
    FROM PostTags pt
    JOIN Posts p ON pt.PostId = p.Id
    GROUP BY Tag
),
TopTags AS (
    SELECT 
        Tag,
        QuestionCount,
        ExampleTitles,
        RANK() OVER (ORDER BY QuestionCount DESC) AS Rank
    FROM TagStatistics
    WHERE QuestionCount > 5  
)
SELECT 
    t.Tag,
    t.QuestionCount,
    t.ExampleTitles,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM TopTags t
LEFT JOIN (
    SELECT 
        pt.Tag AS TagName,
        COUNT(*) AS BadgeCount
    FROM Badges b
    JOIN Users u ON b.UserId = u.Id
    JOIN Posts p ON u.Id = p.OwnerUserId
    JOIN PostTags pt ON p.Id = pt.PostId
    GROUP BY pt.Tag
) b ON t.Tag = b.TagName
ORDER BY t.Rank;
