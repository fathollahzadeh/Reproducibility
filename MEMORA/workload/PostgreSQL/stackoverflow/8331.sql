
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
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
        TotalPosts,
        QuestionCount,
        AnswerCount,
        TotalUpVotes,
        TotalDownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStats
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    COALESCE(ROUND(((CAST(tu.TotalUpVotes AS FLOAT) / NULLIF(tu.TotalPosts, 0)) * 100), 2), 0) AS UpVotePercentage,
    COALESCE(ROUND(((CAST(tu.TotalDownVotes AS FLOAT) / NULLIF(tu.TotalPosts, 0)) * 100), 2), 0) AS DownVotePercentage,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Tags t 
     JOIN Posts p ON t.WikiPostId = p.Id 
     WHERE p.OwnerUserId = tu.UserId) AS TagsContributed
FROM 
    TopUsers tu
WHERE 
    tu.ReputationRank <= 50
ORDER BY 
    tu.Reputation DESC;
