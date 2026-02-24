
WITH UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        (u.UpVotes - u.DownVotes) AS NetVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        NetVotes, 
        PostCount, 
        QuestionCount, 
        AnswerCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserScores
),
RecentPostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS RecentPostCount,
        MAX(p.CreationDate) AS MostRecentPostDate
    FROM 
        Posts p
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tu.NetVotes,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    rps.RecentPostCount,
    rps.MostRecentPostDate
FROM 
    TopUsers tu
LEFT JOIN 
    RecentPostStats rps ON tu.UserId = rps.OwnerUserId
WHERE 
    tu.ReputationRank <= 10
ORDER BY 
    tu.Reputation DESC;
