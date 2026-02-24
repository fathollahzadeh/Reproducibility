WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), 
UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CASE 
            WHEN Reputation >= 1000 THEN 'High'
            WHEN Reputation BETWEEN 100 AND 999 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory
    FROM 
        Users
), 
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        ur.ReputationCategory,
        COALESCE(SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END), 0) AS VoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.Score, ur.ReputationCategory
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.CreationDate,
    ps.Score,
    ps.ReputationCategory,
    ps.VoteCount,
    CASE 
        WHEN ps.VoteCount > 10 THEN 'Popular'
        ELSE 'Less Popular'
    END AS Popularity
FROM 
    PostStats ps
WHERE 
    ps.Score > 0 
    AND ps.ReputationCategory = 'High'
ORDER BY 
    ps.VoteCount DESC, ps.CreationDate DESC
LIMIT 10;