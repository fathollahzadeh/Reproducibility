
WITH UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UpVotes,
        DownVotes,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserScores
    WHERE 
        Reputation > 100
),
PostStatistics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END), 0) AS PositiveScores,
        COALESCE(SUM(CASE WHEN p.CommentCount > 0 THEN 1 ELSE 0 END), 0) AS PostsWithComments
    FROM 
        PostTypes pt
    LEFT JOIN 
        Posts p ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.UpVotes,
    tu.DownVotes,
    tu.QuestionCount,
    tu.AnswerCount,
    ps.PostType,
    ps.PostCount,
    ps.PositiveScores,
    ps.PostsWithComments
FROM 
    TopUsers tu
JOIN 
    PostStatistics ps ON tu.AnswerCount > 10
ORDER BY 
    tu.ReputationRank, ps.PostCount DESC
FETCH FIRST 50 ROWS ONLY;
