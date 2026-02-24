
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
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
        QuestionCount,
        AnswerCount,
        UpVotesCount,
        DownVotesCount,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank
    FROM 
        UserActivity
    WHERE 
        PostCount > 0
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    COALESCE(ROUND(100.0 * tu.UpVotesCount / NULLIF(tu.PostCount, 0), 2), 0) AS UpVotePercentage,
    COALESCE(ROUND(100.0 * tu.DownVotesCount / NULLIF(tu.PostCount, 0), 2), 0) AS DownVotePercentage,
    CASE 
        WHEN tu.PostCount > 100 THEN 'Expert'
        WHEN tu.PostCount > 50 THEN 'Pro'
        ELSE 'Novice'
    END AS UserCategory,
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM Badges b
            WHERE b.UserId = tu.UserId AND b.Class = 1
        ) THEN 'Gold'
        WHEN EXISTS (
            SELECT 1
            FROM Badges b
            WHERE b.UserId = tu.UserId AND b.Class = 2
        ) THEN 'Silver'
        WHEN EXISTS (
            SELECT 1
            FROM Badges b
            WHERE b.UserId = tu.UserId AND b.Class = 3
        ) THEN 'Bronze'
        ELSE 'No Badge'
    END AS BadgeStatus
FROM 
    TopUsers tu
WHERE 
    tu.PostRank <= 10
ORDER BY 
    tu.PostRank;
