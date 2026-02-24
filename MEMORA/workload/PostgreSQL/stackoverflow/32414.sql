
WITH RecursiveUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(p.Id) DESC) AS ActivityRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
    HAVING COUNT(p.Id) > 0
),

RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        p.Title,
        p.PostTypeId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CommentRank
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
)

SELECT 
    ua.DisplayName,
    ua.Reputation,
    ua.PostCount,
    ua.QuestionCount,
    ua.AnswerCount,
    rp.Title,
    rp.Comment,
    rp.CreationDate AS LastCommentDate,
    CASE 
        WHEN rp.Comment IS NOT NULL THEN 'Engaged'
        ELSE 'Inactive'
    END AS EngagementStatus
FROM RecursiveUserActivity ua
LEFT JOIN RecentPostHistory rp ON ua.UserId = rp.UserId
WHERE ua.ActivityRank = 1  
ORDER BY ua.Reputation DESC, LastCommentDate DESC
LIMIT 50;
