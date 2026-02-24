WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS PostLevel
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
  
    UNION ALL
  
    SELECT 
        p2.Id,
        p2.Title,
        p2.ParentId,
        ph.PostLevel + 1
    FROM 
        Posts p2
    INNER JOIN 
        PostHierarchy ph ON p2.ParentId = ph.PostId
), MostVotedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END), 0) AS NetVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2)  
    GROUP BY 
        p.Id, p.Title
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
), ClosestPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.AcceptedAnswerId,
        ph.PostLevel,
        ph.Title AS ParentPostTitle
    FROM 
        Posts p
    LEFT JOIN 
        PostHierarchy ph ON p.Id = ph.PostId
    WHERE 
        ph.PostLevel = 1
)
SELECT 
    cp.Title AS QuestionTitle,
    cp.ParentPostTitle AS ParentOfQuestion, 
    CASE 
        WHEN cp.AcceptedAnswerId IS NOT NULL THEN 
            (SELECT Title FROM Posts WHERE Id = cp.AcceptedAnswerId)
        ELSE 
            'No accepted answer'
    END AS AcceptedAnswerTitle,
    mvp.Title AS MostVotedAnswer,
    mvp.NetVotes,
    ur.DisplayName,
    ur.Reputation,
    ur.ReputationRank
FROM 
    ClosestPosts cp
LEFT JOIN 
    MostVotedPosts mvp ON mvp.Id = cp.AcceptedAnswerId
JOIN 
    UserReputation ur ON ur.UserId = cp.AcceptedAnswerId
ORDER BY 
    cp.Title,
    ur.Reputation DESC;