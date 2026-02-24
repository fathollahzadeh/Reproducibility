
WITH TagFrequency AS (
    SELECT 
        tag.value AS Tag,
        COUNT(*) AS Frequency
    FROM (
        SELECT 
            UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS value
        FROM Posts
        WHERE PostTypeId = 1  
    ) AS tag
    GROUP BY tag.value
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        COUNT(DISTINCT p.Id) AS AnswerCount
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 2  
    GROUP BY u.Id, u.DisplayName
),
TagPostCount AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY t.TagName
),
HighlyActiveUsers AS (
    SELECT 
        pu.UserId, 
        pu.DisplayName, 
        pu.TotalViews, 
        pu.UpVotes,
        ROW_NUMBER() OVER (ORDER BY pu.TotalViews DESC) AS Rank
    FROM PopularUsers pu
    WHERE pu.AnswerCount > 10
)
SELECT 
    tf.Tag,
    tf.Frequency,
    tp.PostCount,
    hau.DisplayName AS ActiveUser,
    hau.TotalViews,
    hau.UpVotes
FROM TagFrequency tf
JOIN TagPostCount tp ON tf.Tag = tp.TagName
LEFT JOIN HighlyActiveUsers hau ON tp.PostCount > 5  
ORDER BY tf.Frequency DESC, tp.PostCount DESC;
