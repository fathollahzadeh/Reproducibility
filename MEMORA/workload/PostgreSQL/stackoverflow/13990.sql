
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM Users AS u
    LEFT JOIN Badges AS b ON u.Id = b.UserId
    LEFT JOIN Votes AS v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount
    FROM Posts AS p
    GROUP BY p.OwnerUserId
),
CombinedStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.BadgeCount,
        us.UpVotes,
        us.DownVotes,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COALESCE(ps.QuestionCount, 0) AS QuestionCount,
        COALESCE(ps.AnswerCount, 0) AS AnswerCount
    FROM UserStats AS us
    LEFT JOIN PostStats AS ps ON us.UserId = ps.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    UpVotes,
    DownVotes,
    PostCount,
    TotalScore,
    TotalViews,
    QuestionCount,
    AnswerCount
FROM CombinedStats
ORDER BY TotalScore DESC
LIMIT 100;
