
WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS Frequency
    FROM Posts
    WHERE PostTypeId = 1 
    GROUP BY unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><'))
),
TopTags AS (
    SELECT 
        TagName,
        Frequency,
        ROW_NUMBER() OVER (ORDER BY Frequency DESC) AS Rank
    FROM TagCounts
)
SELECT 
    t.TagName,
    t.Frequency AS UsageCount,
    p.Title AS PostTitle,
    p.CreationDate AS PostDate,
    u.DisplayName AS AuthorName,
    u.Reputation AS AuthorReputation,
    COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount
FROM TopTags t
JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
JOIN Users u ON u.Id = p.OwnerUserId
WHERE t.Rank <= 10 
ORDER BY t.Frequency DESC, p.ViewCount DESC;
