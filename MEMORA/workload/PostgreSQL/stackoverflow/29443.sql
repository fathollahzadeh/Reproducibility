WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
TopPostByUsers AS (
    SELECT 
        rp.OwnerDisplayName,
        rp.Reputation,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
),
KeywordStatistics AS (
    SELECT 
        LOWER(tag) AS Keyword,
        COUNT(*) AS Count
    FROM 
        Posts p,
        UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tag
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        LOWER(tag)
),
TopKeywords AS (
    SELECT 
        Keyword,
        COUNT AS UsageCount,
        ROW_NUMBER() OVER (ORDER BY COUNT DESC) AS Rank
    FROM 
        KeywordStatistics
    WHERE 
        COUNT > 1
)
SELECT 
    tuv.OwnerDisplayName,
    tuv.Reputation,
    tuv.Title,
    tuv.Score,
    tuv.ViewCount,
    tuv.CreationDate,
    tk.Keyword AS PopularKeyword,
    tk.UsageCount
FROM 
    TopPostByUsers tuv
LEFT JOIN
    TopKeywords tk ON tuv.Title ILIKE CONCAT('%', tk.Keyword, '%')
WHERE 
    tk.Rank <= 10
ORDER BY 
    tuv.Reputation DESC, 
    tuv.Score DESC;