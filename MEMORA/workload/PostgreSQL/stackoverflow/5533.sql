
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS PostCount, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount, 
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
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
        UpVotes, 
        DownVotes,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank,
        RANK() OVER (ORDER BY UpVotes DESC) AS UpVoteRank
    FROM 
        UserActivity
)
SELECT 
    t.UserId, 
    t.DisplayName, 
    t.PostCount, 
    t.QuestionCount, 
    t.AnswerCount, 
    t.UpVotes, 
    t.DownVotes, 
    (SELECT COUNT(*) FROM TopUsers WHERE PostRank <= t.PostRank) AS TotalTopPosters, 
    (SELECT COUNT(*) FROM TopUsers WHERE UpVoteRank <= t.UpVoteRank) AS TotalTopUpvoted
FROM 
    TopUsers t
WHERE 
    t.PostCount > 10
ORDER BY 
    t.PostCount DESC, 
    t.UpVotes DESC 
FETCH FIRST 10 ROWS ONLY;
