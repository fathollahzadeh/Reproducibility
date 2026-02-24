WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
TagStatistics AS (
    SELECT 
        REPLACE(tag.tagname, '<', '') AS CleanedTag,
        COUNT(*) AS PostCount,
        AVG(p.ViewCount) AS AvgViews,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    CROSS JOIN 
        UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tag(tagname)
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        CleanedTag
),
TopTags AS (
    SELECT 
        CleanedTag,
        PostCount,
        AvgViews,
        AvgScore,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStatistics
    WHERE 
        PostCount > 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerName,
    rp.CommentCount,
    tt.CleanedTag,
    tt.AvgViews,
    tt.AvgScore
FROM 
    RankedPosts rp
JOIN 
    TopTags tt ON tt.CleanedTag = ANY(string_to_array(SUBSTRING(rp.Tags, 2, LENGTH(rp.Tags) - 2), '><'))
WHERE 
    rp.Rank <= 3 
ORDER BY 
    tt.PostCount DESC, rp.ViewCount DESC;