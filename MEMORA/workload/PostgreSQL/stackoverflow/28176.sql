WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TopQuestions AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        AnswerCount,
        CreationDate,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10 
),
TagUsage AS (
    SELECT
        t.TagName,
        COUNT(pt.PostId) AS PostCount,
        SUM(pt.AnswerCount) AS TotalAnswers,
        SUM(pt.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%' 
    JOIN 
        TopQuestions pt ON p.Id = pt.PostId
    GROUP BY 
        t.TagName
    ORDER BY 
        TotalAnswers DESC
)
SELECT 
    tu.TagName,
    tu.PostCount,
    tu.TotalAnswers,
    tu.TotalViews,
    CASE 
        WHEN tu.TotalAnswers > 50 THEN 'Highly Engaged'
        WHEN tu.TotalAnswers BETWEEN 20 AND 50 THEN 'Moderately Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    TagUsage tu
WHERE 
    tu.PostCount > 5 
ORDER BY 
    tu.TotalViews DESC;