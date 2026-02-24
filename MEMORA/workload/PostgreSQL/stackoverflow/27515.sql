WITH UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(b.Class) FILTER (WHERE b.Class IS NOT NULL), 0) AS TotalBadgeClass
    FROM
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        CommentCount,
        QuestionCount,
        AnswerCount,
        TotalBadgeClass,
        RANK() OVER (ORDER BY UpVotes DESC, DownVotes ASC, CommentCount DESC, TotalBadgeClass DESC) AS Rank
    FROM UserActivity
)
SELECT
    tu.DisplayName,
    tu.UpVotes,
    tu.DownVotes,
    tu.CommentCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.TotalBadgeClass,
    CASE 
        WHEN tu.Rank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorType,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = tu.UserId) AS TotalPosts,
    (SELECT COUNT(*) FROM Comments c WHERE c.UserId = tu.UserId) AS TotalUserComments
FROM TopUsers tu
WHERE tu.Rank <= 50
ORDER BY tu.Rank;
