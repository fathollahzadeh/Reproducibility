WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
QuestionStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.AnswerCount = 0 THEN 1 END) AS UnansweredCount,
        MAX(p.CreationDate) AS LatestQuestionDate
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.OwnerUserId
),
PerformanceBenchmark AS (
    SELECT 
        us.DisplayName,
        us.Reputation,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        us.TotalBadgeClass,
        q.UnansweredCount,
        q.LatestQuestionDate,
        (us.TotalPosts * 1.0 / NULLIF(us.Reputation, 0)) AS EngagementScore
    FROM 
        UserStats us
    LEFT JOIN 
        QuestionStats q ON us.UserId = q.OwnerUserId
)
SELECT 
    DisplayName,
    Reputation,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalBadgeClass,
    UnansweredCount,
    LatestQuestionDate,
    EngagementScore
FROM 
    PerformanceBenchmark
WHERE 
    EngagementScore > 0.1
ORDER BY 
    EngagementScore DESC
LIMIT 50
OFFSET 0;
