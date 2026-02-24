
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        QuestionCount,
        AnswerCount,
        TotalUpVotes,
        TotalDownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserActivity
), TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        QuestionCount,
        AnswerCount,
        TotalUpVotes,
        TotalDownVotes
    FROM 
        RankedUsers
    WHERE 
        UserRank <= 10
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    CASE 
        WHEN tu.TotalUpVotes > tu.TotalDownVotes THEN 'Positive Contributor'
        WHEN tu.TotalUpVotes < tu.TotalDownVotes THEN 'Negative Contributor'
        ELSE 'Neutral Contributor'
    END AS ContributorStatus,
    (SELECT COUNT(*) 
     FROM Posts p 
     WHERE p.OwnerUserId = tu.UserId AND p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL) AS AcceptedQuestions
FROM 
    TopUsers tu
LEFT JOIN 
    Badges b ON tu.UserId = b.UserId
WHERE 
    b.Class = 1
GROUP BY 
    tu.UserId, tu.DisplayName, tu.Reputation, tu.QuestionCount, 
    tu.AnswerCount, tu.TotalUpVotes, tu.TotalDownVotes
ORDER BY 
    tu.Reputation DESC;
