
WITH RECURSIVE PostHierarchy AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        0 AS Level
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1  

    UNION ALL

    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        ph.Level + 1
    FROM
        Posts p
    INNER JOIN
        PostHierarchy ph ON ph.PostId = p.ParentId
    WHERE
        p.PostTypeId = 2  
),

PostStats AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN TRUE ELSE FALSE END AS HasAcceptedAnswer,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
)

SELECT 
    ps.Title AS QuestionTitle,
    ps.CreationDate AS QuestionCreationDate,
    ps.AnswerCount AS NumberOfAnswers,
    ps.HasAcceptedAnswer AS HasAcceptedAnswerFlag,
    COALESCE(u.DisplayName, 'Community User') AS BestAnswerer,
    u.Reputation AS UserReputation,
    u.ReputationRank,
    ph.Level AS AnswerLevel,
    ps.TotalBounty AS TotalBountyAmount
FROM 
    PostStats ps
LEFT JOIN (
    SELECT 
        p.Id AS PostId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (PARTITION BY p.ParentId ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 2  
) AS Ranking ON ps.Id = Ranking.PostId
LEFT JOIN UserReputation u ON Ranking.PostId = u.UserId
LEFT JOIN PostHierarchy ph ON ps.Id = ph.PostId
WHERE 
    ps.AnswerCount > 0
ORDER BY 
    ps.CreationDate DESC
LIMIT 100;
