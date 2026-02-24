
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentsCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL (
            SELECT 
                unnest(string_to_array(substr(p.Tags, 2, length(p.Tags) - 2), '> <')) AS TagName
        ) t ON TRUE
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.RankByScore <= 5 THEN 'Top 5 Posts'
            WHEN rp.ViewCount > 1000 THEN 'Highly Viewed'
            ELSE 'Other'
        END AS PostCategory
    FROM 
        RankedPosts rp
)
SELECT 
    PostCategory,
    COUNT(PostId) AS TotalPosts,
    AVG(Score) AS AverageScore,
    AVG(ViewCount) AS AverageViewCount,
    STRING_AGG(DISTINCT OwnerDisplayName, ', ') AS Contributors,
    STRING_AGG(DISTINCT TagList, '; ') AS TagsSummary
FROM 
    FilteredPosts
GROUP BY 
    PostCategory
ORDER BY 
    TotalPosts DESC;
