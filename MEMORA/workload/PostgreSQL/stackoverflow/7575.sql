WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplay,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
      AND p.Score > 0
      AND p.PostTypeId IN (1, 2)  
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS PostCount
    FROM Tags t
    JOIN Posts pt ON pt.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY t.TagName
    ORDER BY PostCount DESC
    LIMIT 10
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplay,
    tt.TagName,
    tt.PostCount
FROM RankedPosts rp
JOIN TopTags tt ON rp.PostId IN (SELECT PostId FROM PostLinks WHERE RelatedPostId = rp.PostId)
WHERE rp.Rank <= 5
ORDER BY rp.Score DESC, rp.ViewCount DESC;