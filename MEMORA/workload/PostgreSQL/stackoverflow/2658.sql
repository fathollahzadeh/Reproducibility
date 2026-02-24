
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        MAX(p.LastActivityDate) AS LastActive
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.OwnerUserId, 
        p.ViewCount, 
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
)
SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.QuestionCount,
    ua.AnswerCount,
    ua.LastActive,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate
FROM UserActivity ua
LEFT JOIN RecentPosts rp ON ua.UserId = rp.OwnerUserId AND rp.rn = 1
WHERE ua.TotalPosts > 5
    AND ua.LastActive >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    AND (SELECT COUNT(*) FROM Votes v WHERE v.UserId = ua.UserId AND v.VoteTypeId = 2) > 0
ORDER BY ua.LastActive DESC
FETCH FIRST 20 ROWS ONLY;
