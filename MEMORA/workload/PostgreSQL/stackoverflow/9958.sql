
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (1, 2) THEN p.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
CommentStats AS (
    SELECT 
        c.UserId,
        COUNT(c.Id) AS CommentCount,
        SUM(c.Score) AS TotalCommentScore
    FROM 
        Comments c
    GROUP BY 
        c.UserId
),
BadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(b.Class) AS TotalBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.TotalScore,
    ups.AcceptedAnswers,
    COALESCE(cs.CommentCount, 0) AS CommentCount,
    COALESCE(cs.TotalCommentScore, 0) AS TotalCommentScore,
    COALESCE(bc.BadgeCount, 0) AS BadgeCount,
    COALESCE(bc.TotalBadgeClass, 0) AS TotalBadgeClass
FROM 
    UserPostStats ups
LEFT JOIN 
    CommentStats cs ON ups.UserId = cs.UserId
LEFT JOIN 
    BadgeCounts bc ON ups.UserId = bc.UserId
ORDER BY 
    ups.TotalScore DESC, 
    COALESCE(bc.BadgeCount, 0) DESC, 
    ups.PostCount DESC
LIMIT 100;
