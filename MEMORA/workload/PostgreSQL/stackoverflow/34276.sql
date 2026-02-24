WITH RecursivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS TotalQuestions,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        u.Id, u.Reputation
),
VoteStatistics AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Votes 
    GROUP BY 
        PostId
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseOpenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ur.TotalQuestions,
    ur.AcceptedAnswers,
    COALESCE(vs.TotalUpvotes, 0) AS TotalUpvotes,
    COALESCE(vs.TotalDownvotes, 0) AS TotalDownvotes,
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.Score,
    ph.LastEditDate,
    ph.CloseOpenCount
FROM 
    Users u
JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    RecursivePosts pp ON u.Id = pp.OwnerUserId AND pp.PostRank = 1 
LEFT JOIN 
    VoteStatistics vs ON pp.PostId = vs.PostId
LEFT JOIN 
    PostHistoryStats ph ON pp.PostId = ph.PostId
WHERE 
    u.Reputation > 1000
AND 
    pp.Score > 0
ORDER BY 
    u.Reputation DESC, pp.CreationDate DESC
LIMIT 50;