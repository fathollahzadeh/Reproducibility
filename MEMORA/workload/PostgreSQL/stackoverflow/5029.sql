
WITH UserScore AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
BadgeCount AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostActivity AS (
    SELECT 
        p.OwnerUserId,
        MAX(p.LastActivityDate) AS LastActivity
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.DisplayName,
    us.UpVotes,
    us.DownVotes,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    COALESCE(bc.TotalBadges, 0) AS TotalBadges,
    pa.LastActivity
FROM 
    Users u
JOIN 
    UserScore us ON u.Id = us.UserId
LEFT JOIN 
    BadgeCount bc ON u.Id = bc.UserId
LEFT JOIN 
    PostActivity pa ON u.Id = pa.OwnerUserId
WHERE 
    us.UpVotes >= 10
ORDER BY 
    us.PostCount DESC,
    us.UpVotes DESC;
