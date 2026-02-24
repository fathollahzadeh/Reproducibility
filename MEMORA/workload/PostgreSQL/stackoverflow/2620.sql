
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.Score) AS AverageScore,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
QuestionStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS QuestionsClosed,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseVotes,
        STRING_AGG(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END, ', ') AS CloseReasons
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 AND
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        p.OwnerUserId
),
FinalStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalQuestions,
        ups.TotalAnswers,
        ups.AverageScore,
        ups.TotalViews,
        qs.QuestionsClosed,
        qs.CloseVotes,
        COALESCE(qs.CloseReasons, 'No close reasons') AS CloseReasons
    FROM 
        UserPostStats ups
    LEFT JOIN 
        QuestionStats qs ON ups.UserId = qs.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    AverageScore,
    TotalViews,
    COALESCE(QuestionsClosed, 0) AS QuestionsClosed,
    COALESCE(CloseVotes, 0) AS CloseVotes,
    REPLACE(CloseReasons, 'NULL', 'No close reasons') AS CloseReasons
FROM 
    FinalStats
ORDER BY 
    TotalPosts DESC, AverageScore DESC
LIMIT 50;
