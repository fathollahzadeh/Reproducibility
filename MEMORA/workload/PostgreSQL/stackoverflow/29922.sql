WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        p.CreationDate,
        p.ViewCount,
        COALESCE(ah.AnswerCount, 0) AS AnswerCount,
        COALESCE(ch.CommentCount, 0) AS CommentCount,
        PERCENT_RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2
        GROUP BY 
            ParentId
    ) ah ON p.Id = ah.ParentId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) ch ON p.Id = ch.PostId
    WHERE 
        p.PostTypeId = 1
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.ViewCount) AS AvgViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AvgViews,
        PERCENT_RANK() OVER (ORDER BY TotalViews DESC) AS PopularityRank
    FROM 
        TagStatistics
)
SELECT 
    rp.Title,
    rp.Author,
    rp.CreationDate,
    rp.ViewCount,
    tt.TagName,
    tt.PostCount,
    tt.TotalViews,
    tt.AvgViews,
    rp.ViewRank
FROM 
    RankedPosts rp
JOIN 
    TopTags tt ON rp.Tags LIKE CONCAT('%<', tt.TagName, '>%')
WHERE 
    tt.PopularityRank <= 0.1 
ORDER BY 
    rp.ViewCount DESC, rp.CreationDate DESC;