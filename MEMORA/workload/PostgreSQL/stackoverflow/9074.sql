WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN COALESCE(p.AcceptedAnswerId, 0) END) AS AcceptedAnswers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
BadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
QuestionStats AS (
    SELECT 
        p.OwnerUserId,
        MAX(p.CreationDate) AS LastQuestionDate,
        COUNT(DISTINCT p.Id) AS QuestionsAnswered
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.QuestionsCount,
    us.AnswersCount,
    us.AcceptedAnswers,
    us.TotalViews,
    us.TotalScore,
    COALESCE(bc.BadgeCount, 0) AS BadgeCount,
    COALESCE(qs.LastQuestionDate, '1970-01-01') AS LastQuestionDate,
    COALESCE(qs.QuestionsAnswered, 0) AS QuestionsAnswered
FROM 
    UserStats us
LEFT JOIN 
    BadgeCounts bc ON us.UserId = bc.UserId
LEFT JOIN 
    QuestionStats qs ON us.UserId = qs.OwnerUserId
ORDER BY 
    us.TotalScore DESC, us.Reputation DESC;
