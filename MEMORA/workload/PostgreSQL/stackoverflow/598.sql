
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS PostCount,
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
HighestScoringPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) 
),
AcceptedAnswers AS (
    SELECT 
        p.Id AS AnswerId,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        p.Score AS AnswerScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.PostCount,
    ur.TotalUpVotes,
    ur.TotalDownVotes,
    hp.PostId,
    hp.Title,
    CASE 
        WHEN aa.AnswerId IS NOT NULL THEN aa.AnswerScore
        ELSE 0 
    END AS AcceptedAnswerScore,
    COALESCE(hp.Score, 0) AS HighestScore
FROM 
    UserReputation ur
LEFT JOIN 
    HighestScoringPosts hp ON ur.UserId = hp.OwnerUserId AND hp.Rank = 1
LEFT JOIN 
    AcceptedAnswers aa ON hp.PostId = aa.AcceptedAnswerId
WHERE 
    ur.Reputation > 500
ORDER BY 
    ur.Reputation DESC, 
    HighestScore DESC
LIMIT 50;
