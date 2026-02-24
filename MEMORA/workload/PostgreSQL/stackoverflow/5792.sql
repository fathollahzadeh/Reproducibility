
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.ViewCount DESC) AS RankInType
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankInType <= 5
),
PostStatistics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(tp.PostId) AS TotalPosts,
        AVG(tp.Score) AS AvgScore,
        SUM(tp.ViewCount) AS TotalViews,
        SUM(tp.AnswerCount) AS TotalAnswers,
        SUM(tp.CommentCount) AS TotalComments
    FROM 
        TopPosts tp
    JOIN 
        PostTypes pt ON tp.PostId = pt.Id
    GROUP BY 
        pt.Name
)
SELECT 
    PostType,
    TotalPosts,
    AvgScore,
    TotalViews,
    TotalAnswers,
    TotalComments,
    (TotalViews::DECIMAL / NULLIF(TotalPosts, 0)) AS AvgViewsPerPost,
    (TotalAnswers::DECIMAL / NULLIF(TotalPosts, 0)) AS AvgAnswersPerPost,
    (TotalComments::DECIMAL / NULLIF(TotalPosts, 0)) AS AvgCommentsPerPost
FROM 
    PostStatistics
ORDER BY 
    AvgScore DESC, TotalPosts DESC;
