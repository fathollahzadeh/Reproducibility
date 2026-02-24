
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CommentCount,
        COALESCE(ph.Comment, 'No edits') AS LastEditComment,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn,
        p.OwnerUserId
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5)
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
)
SELECT 
    ua.DisplayName,
    ua.Reputation,
    ua.PostCount,
    ua.AnswerCount,
    ua.QuestionCount,
    ua.TotalBounties,
    ua.LastPostDate,
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.LastEditComment
FROM UserActivity ua
LEFT JOIN PostDetails pd ON ua.UserId = pd.OwnerUserId
WHERE ua.Reputation > 1000
AND (pd.LastEditComment IS NOT NULL OR pd.rn = 1)
ORDER BY ua.Reputation DESC, ua.PostCount DESC
LIMIT 50;
