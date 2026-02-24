WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
), 
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
), 
UserPostDetails AS (
    SELECT 
        ru.DisplayName,
        ru.UserId,
        ps.TotalPosts,
        ps.TotalQuestions,
        ps.TotalAnswers
    FROM 
        RankedUsers ru
    LEFT JOIN 
        PostStats ps ON ru.UserId = ps.OwnerUserId
)
SELECT 
    u.DisplayName,
    COALESCE(upd.TotalPosts, 0) AS TotalPosts,
    COALESCE(upd.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(upd.TotalAnswers, 0) AS TotalAnswers,
    CASE 
        WHEN COALESCE(upd.TotalPosts, 0) > 0 THEN 
            ROUND(COALESCE(upd.TotalAnswers, 0) * 1.0 / upd.TotalPosts * 100, 2) 
        ELSE 
            0 
    END AS AnswerRate,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Badges b WHERE b.UserId = u.Id AND b.Class = 1) THEN 'Gold' 
        WHEN EXISTS (SELECT 1 FROM Badges b WHERE b.UserId = u.Id AND b.Class = 2) THEN 'Silver' 
        WHEN EXISTS (SELECT 1 FROM Badges b WHERE b.UserId = u.Id AND b.Class = 3) THEN 'Bronze' 
        ELSE 'No Badge' 
    END AS BadgeStatus
FROM 
    Users u
LEFT JOIN 
    UserPostDetails upd ON u.Id = upd.UserId
WHERE 
    u.Id IS NOT NULL
ORDER BY 
    AnswerRate DESC NULLS LAST, TotalPosts DESC;