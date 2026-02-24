
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        PostCount, 
        Questions, 
        Answers, 
        AcceptedAnswers, 
        UpVotes, 
        DownVotes,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM UserActivity
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    tu.UserId,
    u.DisplayName,
    u.Reputation,
    tu.PostCount,
    tu.Questions,
    tu.Answers,
    tu.AcceptedAnswers,
    tu.UpVotes,
    tu.DownVotes,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount
FROM TopUsers tu
JOIN Users u ON tu.UserId = u.Id
LEFT JOIN UserBadges ub ON tu.UserId = ub.UserId
WHERE tu.Rank <= 10
ORDER BY tu.Rank;
