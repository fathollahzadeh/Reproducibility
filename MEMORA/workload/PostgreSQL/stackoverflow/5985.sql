
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ur.BadgeCount,
        ur.UpVotes,
        ur.DownVotes,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.QuestionCount, 0) AS QuestionCount,
        COALESCE(ps.PositiveScoreCount, 0) AS PositiveScoreCount
    FROM UserReputation ur
    LEFT JOIN PostStats ps ON ur.UserId = ps.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    BadgeCount,
    UpVotes,
    DownVotes,
    PostCount,
    QuestionCount,
    PositiveScoreCount,
    CASE 
        WHEN Reputation IS NULL OR Reputation < 0 THEN 'Newbie'
        WHEN Reputation < 1000 THEN 'Intermediate'
        WHEN Reputation < 5000 THEN 'Expert'
        ELSE 'Pro'
    END AS UserLevel
FROM UserPerformance
ORDER BY Reputation DESC, BadgeCount DESC;
