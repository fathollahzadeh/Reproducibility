
WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
TagFrequencies AS (
    SELECT 
        Tag,
        COUNT(*) AS Frequency
    FROM 
        PostTagCounts
    GROUP BY 
        Tag
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
)
SELECT 
    tf.Tag,
    tf.Frequency,
    au.UserId,
    au.PostCount,
    (SELECT COUNT(DISTINCT p.Id) 
     FROM Posts p 
     WHERE p.Tags LIKE '%' || tf.Tag || '%') AS TotalPostsWithTag
FROM 
    TagFrequencies tf
CROSS JOIN 
    ActiveUsers au
WHERE 
    tf.Frequency > 5
ORDER BY 
    tf.Frequency DESC, au.PostCount DESC;
