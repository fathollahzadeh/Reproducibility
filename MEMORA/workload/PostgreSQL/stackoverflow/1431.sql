WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        DENSE_RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS ActivityRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 0
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT UserId, DisplayName, TotalPosts, TotalAnswers, TotalQuestions, UpVotes, DownVotes
    FROM UserActivity
    WHERE ActivityRank <= 10
),
UserBadges AS (
    SELECT 
        b.UserId, 
        STRING_AGG(b.Name, ', ') AS BadgeNames, 
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalAnswers,
    tu.TotalQuestions,
    tu.UpVotes,
    tu.DownVotes,
    COALESCE(ub.BadgeNames, 'No Badges') AS BadgeNames,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount
FROM TopUsers tu
LEFT JOIN UserBadges ub ON tu.UserId = ub.UserId
ORDER BY tu.TotalPosts DESC, tu.UpVotes DESC;
