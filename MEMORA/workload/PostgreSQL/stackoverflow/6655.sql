
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        AVG(u.Reputation) AS AvgReputation,
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
HighReputationUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        AnswerCount,
        QuestionCount,
        AvgReputation,
        UpVotes,
        DownVotes
    FROM 
        UserPostStats
    WHERE 
        AvgReputation > 1000
),
TopAnswerers AS (
    SELECT 
        UserId,
        DisplayName,
        AnswerCount
    FROM 
        HighReputationUsers
    WHERE 
        AnswerCount > 10
    ORDER BY 
        AnswerCount DESC
    LIMIT 5
)
SELECT 
    u.DisplayName,
    u.PostCount,
    u.QuestionCount,
    u.AnswerCount,
    u.UpVotes,
    u.DownVotes,
    ROUND(COALESCE((SELECT SUM(b.Class) FROM Badges b WHERE b.UserId = u.UserId), 0), 2) AS TotalBadgeScore
FROM 
    HighReputationUsers u
JOIN 
    TopAnswerers t ON u.UserId = t.UserId
ORDER BY 
    u.UpVotes - u.DownVotes DESC;
