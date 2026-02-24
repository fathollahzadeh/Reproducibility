
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 
),

TagDetails AS (
    SELECT 
        p.Id AS PostId,
        TRIM(BOTH '>' FROM Tag) AS Tag
    FROM Posts p
    CROSS JOIN UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS Tag
    WHERE p.Tags IS NOT NULL
),

TagStats AS (
    SELECT 
        td.Tag,
        COUNT(*) AS TagCount,
        AVG(rp.Score) AS AvgScore,
        SUM(rp.ViewCount) AS TotalViews
    FROM TagDetails td
    JOIN RankedPosts rp ON td.PostId = rp.PostId
    GROUP BY td.Tag
),

TopTags AS (
    SELECT 
        ts.Tag,
        RANK() OVER (ORDER BY ts.TagCount DESC) AS TagRank
    FROM TagStats ts
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    rp.Reputation,
    tt.Tag,
    ts.TagCount,
    ts.AvgScore,
    ts.TotalViews
FROM RankedPosts rp
JOIN TopTags tt ON tt.Tag IN (
    SELECT TRIM(BOTH '>' FROM Tag) 
    FROM UNNEST(string_to_array(SUBSTRING(rp.Tags FROM 2 FOR LENGTH(rp.Tags) - 2), '><')) AS Tag
)
JOIN TagStats ts ON tt.Tag = ts.Tag
WHERE rp.RankByScore = 1 AND tt.TagRank <= 5 
ORDER BY ts.TagCount DESC, rp.Score DESC;
