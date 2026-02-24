WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        SUM(CASE WHEN b.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
UserRanking AS (
    SELECT 
        ua.UserId,
        ua.PostCount,
        ua.QuestionCount,
        ua.AnswerCount,
        ua.UpVotesCount - ua.DownVotesCount AS VotingBalance,
        ua.BadgeCount,
        RANK() OVER (ORDER BY ua.UpVotesCount DESC, ua.PostCount DESC) AS UserRank
    FROM UserActivity ua
)
SELECT 
    ur.UserId,
    u.DisplayName,
    ur.PostCount,
    ur.QuestionCount,
    ur.AnswerCount,
    ur.VotingBalance,
    ur.BadgeCount,
    ur.UserRank
FROM UserRanking ur
JOIN Users u ON ur.UserId = u.Id
WHERE ur.UserRank <= 10
ORDER BY ur.UserRank;
