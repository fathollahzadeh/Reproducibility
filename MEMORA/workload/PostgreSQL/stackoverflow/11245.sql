
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
BadgeCount AS (
    SELECT 
        UserId,
        COUNT(Id) AS BadgeTotal
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    u.DisplayName,
    us.PostCount,
    us.CommentCount,
    us.UpVotes,
    us.DownVotes,
    us.QuestionCount,
    us.AnswerCount,
    COALESCE(bc.BadgeTotal, 0) AS TotalBadges
FROM 
    Users u
JOIN 
    UserPostStats us ON u.Id = us.UserId
LEFT JOIN 
    BadgeCount bc ON u.Id = bc.UserId
ORDER BY 
    us.PostCount DESC, us.UpVotes DESC
LIMIT 50;
