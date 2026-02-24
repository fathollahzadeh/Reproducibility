WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.Score, p.ViewCount
),
TagMetrics AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS QuestionCount, 
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%' 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        t.Id, t.TagName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        tm.TagName,
        tm.QuestionCount,
        tm.TotalViews,
        tm.TotalScore
    FROM 
        RankedPosts rp
    JOIN 
        TagMetrics tm ON rp.Tags LIKE '%' || tm.TagName || '%'
    WHERE 
        rp.CommentCount > 0 AND 
        rp.VoteCount > 5 
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.TagName,
    fp.QuestionCount,
    fp.TotalViews,
    fp.TotalScore
FROM 
    FilteredPosts fp
ORDER BY 
    fp.TotalViews DESC 
LIMIT 10;