
WITH UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
UserBadges AS (
    SELECT
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
),
TopUsers AS (
    SELECT
        ups.UserId,
        ups.DisplayName,
        ups.PostCount,
        ups.QuestionCount,
        ups.AnswerCount,
        ups.UpVoteCount,
        ups.DownVoteCount,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        ub.BadgeNames
    FROM UserPostStats ups
    LEFT JOIN UserBadges ub ON ups.UserId = ub.UserId
    WHERE ups.PostCount > 0
    ORDER BY ups.QuestionCount DESC, ups.UpVoteCount DESC
    LIMIT 10
)
SELECT
    tu.UserId,
    tu.DisplayName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.UpVoteCount,
    tu.DownVoteCount,
    tu.BadgeCount,
    COALESCE(tu.BadgeNames, 'No Badges') AS BadgeNames,
    CASE
        WHEN tu.UpVoteCount > tu.DownVoteCount THEN 'Positive Contributor'
        WHEN tu.UpVoteCount < tu.DownVoteCount THEN 'Negative Contributor'
        ELSE 'Neutral Contributor'
    END AS ContributorStatus
FROM TopUsers tu
ORDER BY tu.QuestionCount DESC, tu.UpVoteCount DESC;
