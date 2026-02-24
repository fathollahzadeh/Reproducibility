WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
        AND p.Score > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.PostCount,
        RANK() OVER (ORDER BY ur.Reputation DESC) AS ReputationRank
    FROM 
        UserReputation ur
    WHERE 
        ur.Reputation > 1000
)
SELECT 
    u.DisplayName,
    p.Title,
    p.Score,
    COALESCE(ph.Comment, 'No History') AS PostHistoryComment,
    t.TagName
FROM 
    RankedPosts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostHistory ph ON ph.PostId = p.PostId AND ph.PostHistoryTypeId = 10
LEFT JOIN 
    PostLinks pl ON pl.PostId = p.PostId
LEFT JOIN 
    Posts rp ON pl.RelatedPostId = rp.Id
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.PostId
WHERE 
    p.PostRank = 1
    AND u.Id IN (SELECT UserId FROM TopUsers WHERE ReputationRank <= 10)
ORDER BY 
    p.Score DESC, 
    p.CreationDate DESC;