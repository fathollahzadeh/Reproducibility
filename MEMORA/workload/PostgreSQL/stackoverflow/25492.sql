
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TagStatistics AS (
    SELECT 
        unnest(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS Tag,
        COUNT(*) AS TotalCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        unnest(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><'))
),
TopTags AS (
    SELECT 
        Tag,
        TotalCount,
        TotalViews,
        RANK() OVER (ORDER BY TotalViews DESC) AS Rank
    FROM 
        TagStatistics
)
SELECT 
    tp.Tag,
    tp.TotalCount,
    tp.TotalViews,
    rp.Title,
    rp.ViewCount AS MostViewedCount,
    rp.AnswerCount,
    rp.CommentCount
FROM 
    TopTags tp
JOIN 
    RankedPosts rp ON tp.Tag = ANY(string_to_array(SUBSTRING(rp.Tags FROM 2 FOR LENGTH(rp.Tags) - 2), '><'))
WHERE 
    tp.Rank <= 10
    AND rp.TagRank = 1
ORDER BY 
    tp.Rank, rp.ViewCount DESC;
