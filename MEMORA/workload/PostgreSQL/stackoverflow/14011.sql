WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
AveragePostScore AS (
    SELECT 
        AVG(Score) AS AvgScore
    FROM 
        Posts
    WHERE 
        Score IS NOT NULL
),
BadgesCount AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.UpvoteCount,
    ups.DownvoteCount,
    COALESCE(bc.BadgeCount, 0) AS BadgeCount,
    aps.AvgScore
FROM 
    UserPostStats ups
LEFT JOIN 
    BadgesCount bc ON ups.UserId = bc.UserId
CROSS JOIN 
    AveragePostScore aps
ORDER BY 
    ups.PostCount DESC;