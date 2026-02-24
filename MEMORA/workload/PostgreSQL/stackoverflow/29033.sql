
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        t.TagName,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        UNNEST(string_to_array(p.Tags, '<>')) AS t(TagName) ON true
    WHERE 
        p.PostTypeId = 1 
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        TagName
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 3 
),
PostStats AS (
    SELECT 
        tp.TagName,
        COUNT(tp.PostId) AS PostCount,
        AVG(tp.Score) AS AvgScore,
        SUM(tp.ViewCount) AS TotalViews
    FROM 
        TopPosts tp
    GROUP BY 
        tp.TagName
)
SELECT 
    ps.TagName,
    ps.PostCount,
    ps.AvgScore,
    ps.TotalViews,
    p.PostId,
    p.Title,
    p.CreationDate
FROM 
    PostStats ps
JOIN 
    TopPosts p ON ps.TagName = p.TagName
ORDER BY 
    ps.AvgScore DESC, ps.PostCount DESC;
