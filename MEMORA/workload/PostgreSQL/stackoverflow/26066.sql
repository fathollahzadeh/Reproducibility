WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(p.CommentCount, 0) AS CommentCount,
        COALESCE(p.FavoriteCount, 0) AS FavoriteCount,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'), 1) AS TagCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TagDetails AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(pm.ViewCount) AS TotalViews,
        AVG(pm.Score) AS AverageScore
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%<' || t.TagName || '>%'
    LEFT JOIN 
        PostMetrics pm ON pm.PostId = p.Id
    GROUP BY 
        t.TagName
),
TopPosts AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.OwnerDisplayName,
        pm.OwnerReputation,
        pm.ViewCount,
        pm.AnswerCount,
        pm.CommentCount,
        pm.FavoriteCount,
        pm.TagCount,
        pm.CreationDate
    FROM 
        PostMetrics pm
    ORDER BY 
        pm.Score DESC, pm.ViewCount DESC
    LIMIT 10
)
SELECT 
    td.TagName,
    td.PostCount,
    td.TotalViews,
    td.AverageScore,
    tp.Title AS TopPostTitle,
    tp.OwnerDisplayName AS TopPostOwner,
    tp.ViewCount AS TopPostViewCount,
    tp.CreationDate AS TopPostCreationDate
FROM 
    TagDetails td
LEFT JOIN 
    TopPosts tp ON tp.TagCount > 0
ORDER BY 
    td.PostCount DESC, td.TotalViews DESC;