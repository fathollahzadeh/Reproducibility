
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.ViewCount DESC) AS YearlyRank
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.Score, p.ViewCount, U.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Tags,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        AnswerCount
    FROM 
        RankedPosts
    WHERE 
        YearlyRank <= 10 
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '>')) AS TagName,
        tp.PostId
    FROM 
        TopPosts tp
),
TagStatistics AS (
    SELECT 
        TagName,
        COUNT(*) AS PostCount,
        SUM(tp.ViewCount) AS TotalViews
    FROM 
        PopularTags pt
    JOIN 
        TopPosts tp ON tp.PostId = pt.PostId
    GROUP BY 
        TagName
    ORDER BY 
        TotalViews DESC
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    CASE 
        WHEN ts.TotalViews > 1000 THEN 'High'
        WHEN ts.TotalViews >= 500 AND ts.TotalViews <= 1000 THEN 'Medium'
        ELSE 'Low'
    END AS PopularityLevel
FROM 
    TagStatistics ts
LIMIT 20;
