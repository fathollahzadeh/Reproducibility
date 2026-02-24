WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersProvided,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentsMade,
        COUNT(DISTINCT v.Id) AS VotesReceived
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalBadges
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.QuestionsAsked,
    ua.AnswersProvided,
    ua.CommentsMade,
    ua.VotesReceived,
    COALESCE(bc.TotalBadges, 0) AS TotalBadges
FROM 
    UserActivity ua
LEFT JOIN 
    BadgeCounts bc ON ua.UserId = bc.UserId
ORDER BY 
    ua.VotesReceived DESC,
    ua.QuestionsAsked DESC,
    TotalBadges DESC
LIMIT 10;

