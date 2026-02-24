
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN pt.Name = 'Question' THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(u.Reputation) AS AvgReputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        AnswerCount,
        QuestionCount,
        UpVotes,
        DownVotes,
        AvgReputation,
        BadgeCount,
        RANK() OVER (ORDER BY PostCount DESC, UpVotes DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.PostCount,
    t.AnswerCount,
    t.QuestionCount,
    t.UpVotes,
    t.DownVotes,
    t.AvgReputation,
    t.BadgeCount,
    (SELECT STRING_AGG(DISTINCT CASE WHEN p.Tags IS NOT NULL THEN p.Tags END, ', ') 
     FROM Posts p 
     WHERE p.OwnerUserId = t.UserId) AS Tags 
FROM 
    TopUsers t
WHERE 
    t.Rank <= 10
ORDER BY 
    t.Rank;
