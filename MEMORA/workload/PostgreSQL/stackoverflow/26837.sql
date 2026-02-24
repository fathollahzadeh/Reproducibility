
WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS PostCount, 
        SUM(COALESCE(v.UpVotes, 0)) AS TotalUpVotes, 
        SUM(COALESCE(v.DownVotes, 0)) AS TotalDownVotes,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
                SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM Votes 
         GROUP BY PostId) v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
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
        RANK() OVER (ORDER BY TotalUpVotes DESC) AS UpVoteRank
    FROM 
        UserStats
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.PostCount,
    u.TotalUpVotes,
    u.TotalDownVotes,
    u.QuestionCount,
    u.AnswerCount,
    ARRAY_AGG(t.Title) AS TopQuestions
FROM 
    TopUsers u
LEFT JOIN 
    (SELECT 
         p.OwnerUserId, 
         p.Title, 
         p.ViewCount,
         ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS QuestionRank
     FROM 
         Posts p
     WHERE 
         p.PostTypeId = 1) t ON u.UserId = t.OwnerUserId AND t.QuestionRank <= 5
WHERE 
    u.UpVoteRank <= 10
GROUP BY 
    u.DisplayName, 
    u.Reputation, 
    u.PostCount, 
    u.TotalUpVotes, 
    u.TotalDownVotes,
    u.QuestionCount,
    u.AnswerCount
ORDER BY 
    u.TotalUpVotes DESC;
