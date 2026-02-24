WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.AnswerCount > 0 
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 
),
PostStatistics AS (
    SELECT 
        t.TagName,
        COUNT(tp.PostId) AS TotalQuestions,
        AVG(tp.Score) AS AvgScore,
        SUM(tp.ViewCount) AS TotalViews
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        TopPosts tp ON p.Id = tp.PostId
    GROUP BY 
        t.TagName
)
SELECT 
    ps.TagName,
    ps.TotalQuestions,
    ps.AvgScore,
    ps.TotalViews,
    ct.NeedDetailsOrClarityCount
FROM 
    PostStatistics ps
LEFT JOIN 
    (SELECT 
        COUNT(*) AS NeedDetailsOrClarityCount
     FROM 
        PostHistory ph
     WHERE 
        ph.PostHistoryTypeId = 103) ct ON 1=1
ORDER BY 
    ps.TotalViews DESC;