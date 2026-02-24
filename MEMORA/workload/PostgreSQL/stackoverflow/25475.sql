WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionsCount,
        AnswersCount,
        UpVotesCount,
        DownVotesCount,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank,
        RANK() OVER (ORDER BY UpVotesCount DESC) AS UpVoteRank
    FROM 
        UserActivity
),
UserBadges AS (
    SELECT 
        u.Id,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.QuestionsCount,
    tu.AnswersCount,
    tu.UpVotesCount,
    tu.DownVotesCount,
    ub.BadgeCount,
    ub.BadgeNames
FROM 
    TopUsers tu
JOIN 
    UserBadges ub ON tu.UserId = ub.Id
WHERE 
    tu.PostRank <= 10 OR tu.UpVoteRank <= 10
ORDER BY 
    tu.PostCount DESC, tu.UpVotesCount DESC;
