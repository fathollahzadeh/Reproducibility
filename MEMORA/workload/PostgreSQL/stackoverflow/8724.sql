WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(vt.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(vt.DownVotes, 0)) AS TotalDownVotes,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (SELECT PostId, 
                    SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
                    SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
                 FROM Votes 
                 GROUP BY PostId) vt ON p.Id = vt.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        TotalUpVotes,
        TotalDownVotes,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        RANK() OVER (ORDER BY PostCount DESC) AS PostCountRank
    FROM UserStats
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.PostCount,
    u.TotalUpVotes,
    u.TotalDownVotes,
    u.QuestionCount,
    u.AnswerCount,
    CASE 
        WHEN u.ReputationRank <= 10 THEN 'Top Reputation'
        ELSE 'Standard Reputation'
    END AS ReputationCategory,
    CASE 
        WHEN u.PostCountRank <= 10 THEN 'Top Contributor'
        ELSE 'Standard Contributor'
    END AS ContributionCategory
FROM TopUsers u
WHERE u.PostCount > 0
ORDER BY u.Reputation DESC, u.PostCount DESC
LIMIT 50;
