
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 100
    GROUP BY u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
ActiveUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostCount,
        ua.QuestionCount,
        ua.AnswerCount,
        ua.UpVotes,
        ua.DownVotes,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount
    FROM UserActivity ua
    LEFT JOIN UserBadges ub ON ua.UserId = ub.UserId
)
SELECT 
    au.DisplayName,
    au.PostCount,
    au.QuestionCount,
    au.AnswerCount,
    au.UpVotes,
    au.DownVotes,
    au.BadgeCount,
    ROW_NUMBER() OVER (ORDER BY au.PostCount DESC, au.UpVotes DESC) AS Rank
FROM ActiveUsers au
ORDER BY au.PostCount DESC, au.UpVotes DESC
LIMIT 10;
