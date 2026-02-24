WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Tags,
        CreationDate,
        ViewCount,
        AnswerCount,
        CommentCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5  
),
AggregateData AS (
    SELECT 
        t.Tags,
        COUNT(t.PostId) AS TotalPosts,
        SUM(t.ViewCount) AS TotalViews,
        SUM(t.AnswerCount) AS TotalAnswers,
        SUM(t.CommentCount) AS TotalComments,
        STRING_AGG(t.Title, ', ') AS PostTitles 
    FROM 
        TopPosts t
    GROUP BY 
        t.Tags
)

SELECT 
    a.Tags,
    a.TotalPosts,
    a.TotalViews,
    a.TotalAnswers,
    a.TotalComments,
    a.PostTitles,
    CASE 
        WHEN a.TotalPosts > 20 THEN 'High Engagement'
        WHEN a.TotalPosts BETWEEN 10 AND 20 THEN 'Medium Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    AggregateData a
ORDER BY 
    a.TotalPosts DESC;