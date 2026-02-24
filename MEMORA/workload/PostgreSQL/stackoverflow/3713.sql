
WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.OwnerUserId, 
        COUNT(a.Id) AS AnswerCount, 
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankPerUser
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation,
        CASE 
            WHEN u.Reputation < 100 THEN 'Newbie'
            WHEN u.Reputation >= 100 AND u.Reputation <= 1000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS ReputationCategory
    FROM 
        Users u
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        COUNT(ph.Id) AS ClosureCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Title, 
    rp.CreationDate, 
    ur.Reputation, 
    ur.ReputationCategory, 
    COALESCE(cp.ClosureCount, 0) AS ClosureCount, 
    rp.AnswerCount,
    CASE 
        WHEN rp.RankPerUser = 1 THEN 'Most Recent'
        ELSE NULL
    END AS RecentPostIndicator
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId
WHERE 
    ur.Reputation > 100 
ORDER BY 
    rp.CreationDate DESC;
