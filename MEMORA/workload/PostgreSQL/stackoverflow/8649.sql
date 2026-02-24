
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
BadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
),
RankedUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.PostCount,
        us.AnswerCount,
        us.QuestionCount,
        us.UpVotes,
        us.DownVotes,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount,
        RANK() OVER (ORDER BY us.Reputation DESC) AS Rank
    FROM UserStats us
    LEFT JOIN BadgeCounts bc ON us.UserId = bc.UserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    AnswerCount,
    QuestionCount,
    UpVotes,
    DownVotes,
    BadgeCount,
    Rank
FROM RankedUsers
WHERE Rank <= 100
ORDER BY Reputation DESC, PostCount DESC;
