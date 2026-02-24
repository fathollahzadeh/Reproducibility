
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, LENGTH(p.Tags) - 2), '><'), 1) ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
),

TagStats AS (
    SELECT 
        tag,
        COUNT(*) AS PostCount,
        AVG(score) AS AvgScore
    FROM (
        SELECT 
            TRIM(unnest(string_to_array(substring(Tags, 2, LENGTH(Tags) - 2), '><'))) AS tag,
            Score
        FROM 
            Posts
        WHERE 
            PostTypeId = 1
    ) AS TagsData
    GROUP BY 
        tag
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    ts.tag,
    ts.PostCount,
    ts.AvgScore,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount
FROM 
    RankedPosts rp
JOIN 
    TagStats ts ON ts.tag = ANY(string_to_array(substring(rp.Tags, 2, LENGTH(rp.Tags) - 2), '><'))
WHERE 
    rp.Rank <= 5
ORDER BY 
    ts.AvgScore DESC, 
    rp.Score DESC;
