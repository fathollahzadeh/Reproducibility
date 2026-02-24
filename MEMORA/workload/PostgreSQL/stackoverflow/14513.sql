WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        up.PostCount,
        up.QuestionCount,
        up.AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        UserPostCounts up ON u.Id = up.UserId
)
SELECT 
    ua.UserId,
    ua.Reputation,
    ua.CreationDate,
    ua.LastAccessDate,
    ua.Views,
    ua.UpVotes,
    ua.DownVotes,
    ua.PostCount,
    ua.QuestionCount,
    ua.AnswerCount,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM 
    UserActivity ua
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(Id) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) b ON ua.UserId = b.UserId
ORDER BY 
    ua.Reputation DESC, 
    ua.PostCount DESC;