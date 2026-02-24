WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByDate
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),

UserPostSummary AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        COUNT(DISTINCT rp.PostID) AS TotalQuestions,
        SUM(rp.ViewCount) AS TotalViews,
        AVG(rp.ViewCount) AS AvgViewsPerQuestion,
        SUM(rp.AnswerCount) AS TotalAnswers,
        SUM(rp.CommentCount) AS TotalComments,
        MAX(rp.CreationDate) AS LatestQuestionDate
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    ups.UserID,
    ups.DisplayName,
    ups.TotalQuestions,
    ups.TotalViews,
    ups.AvgViewsPerQuestion,
    ups.TotalAnswers,
    ups.TotalComments,
    ups.LatestQuestionDate,
    CASE 
        WHEN ups.TotalQuestions > 10 THEN 'Active Contributor'
        WHEN ups.TotalQuestions BETWEEN 5 AND 10 THEN 'Moderate Contributor'
        ELSE 'Occasional Contributor' 
    END AS ContributorType
FROM 
    UserPostSummary ups
ORDER BY 
    ups.TotalViews DESC, ups.TotalQuestions DESC;