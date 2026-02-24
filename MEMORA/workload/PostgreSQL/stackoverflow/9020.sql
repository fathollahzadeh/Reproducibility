
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.UpVotes,
        u.DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.UpVotes, u.DownVotes
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UpVotes,
        DownVotes,
        PostCount,
        CommentCount,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStats
    WHERE 
        PostCount > 0
),
PopularQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS PopularityRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
)
SELECT 
    t.DisplayName AS TopUser,
    t.Reputation AS UserReputation,
    tp.Title AS PopularQuestion,
    tp.ViewCount AS QuestionViewCount,
    tp.Score AS QuestionScore,
    t.QuestionCount AS UserQuestions,
    t.AnswerCount AS UserAnswers
FROM 
    TopUsers t
JOIN 
    PopularQuestions tp ON t.QuestionCount > 0
WHERE 
    t.ReputationRank <= 10 AND tp.PopularityRank <= 10
ORDER BY 
    t.Reputation DESC, tp.Score DESC;
