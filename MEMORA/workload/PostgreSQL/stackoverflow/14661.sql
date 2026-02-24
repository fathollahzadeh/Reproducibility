WITH PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(p.AnswerCount), 0) AS TotalAnswersReceived,
        COALESCE(SUM(p.CommentCount), 0) AS TotalComments
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        u.LastAccessDate,
        ps.TotalPosts,
        ps.TotalQuestions,
        ps.TotalAnswers,
        ps.TotalScore,
        ps.TotalViews,
        ps.TotalAnswersReceived,
        ps.TotalComments
    FROM 
        Users u
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.CreationDate,
    us.LastAccessDate,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.TotalScore,
    us.TotalViews,
    us.TotalAnswersReceived,
    us.TotalComments
FROM 
    UserStats us
ORDER BY 
    us.Reputation DESC, us.TotalPosts DESC;