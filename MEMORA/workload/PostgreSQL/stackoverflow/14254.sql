WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS PostCount,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        COUNT(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 END) AS ClosedPostCount
    FROM Posts p
    GROUP BY p.OwnerUserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.BadgeCount,
    ps.PostCount,
    ps.QuestionCount,
    ps.AnswerCount,
    ps.ClosedPostCount,
    us.UpVotes,
    us.DownVotes,
    us.TotalViews,
    us.TotalScore
FROM UserStats us
LEFT JOIN PostStats ps ON us.UserId = ps.OwnerUserId
ORDER BY us.TotalScore DESC;