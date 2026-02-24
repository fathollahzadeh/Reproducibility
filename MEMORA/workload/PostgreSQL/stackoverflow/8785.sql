
WITH UserScoreData AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END), 0) AS QuestionCount,
        COALESCE(COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END), 0) AS AnswerCount,
        COALESCE(SUM(p.Score), 0) AS TotalScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
UserBadgeCount AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
)
SELECT 
    usd.UserId,
    usd.DisplayName,
    usd.Reputation,
    usd.UpVotes,
    usd.DownVotes,
    usd.QuestionCount,
    usd.AnswerCount,
    usd.TotalScore,
    COALESCE(ubc.BadgeCount, 0) AS BadgeCount
FROM UserScoreData usd
LEFT JOIN UserBadgeCount ubc ON usd.UserId = ubc.UserId
ORDER BY usd.TotalScore DESC, usd.Reputation DESC
FETCH FIRST 10 ROWS ONLY;
