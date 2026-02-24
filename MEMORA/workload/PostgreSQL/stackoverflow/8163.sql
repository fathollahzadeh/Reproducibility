
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS Author,
        p.OwnerUserId
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 AND p.Score > 0
),
MostActiveUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(ViewCount) AS TotalViews
    FROM Posts
    WHERE PostTypeId = 1
    GROUP BY OwnerUserId
    HAVING COUNT(*) > 10
),
TopTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(Tags, '><'))) AS TagName,
        COUNT(*) AS TagCount
    FROM Posts
    WHERE PostTypeId = 1
    GROUP BY TagName
    ORDER BY TagCount DESC
    LIMIT 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.CreationDate,
    rp.Author,
    mau.PostCount,
    mau.TotalViews,
    tt.TagName
FROM RankedPosts rp
JOIN MostActiveUsers mau ON rp.OwnerUserId = mau.OwnerUserId
CROSS JOIN TopTags tt
WHERE rp.Rank <= 3
ORDER BY rp.ViewCount DESC, rp.Score DESC;
