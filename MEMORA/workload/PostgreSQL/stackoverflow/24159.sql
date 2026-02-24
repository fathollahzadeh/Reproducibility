WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id 
),

RecentActivity AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastModificationDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 10, 11, 14)
    GROUP BY 
        ph.PostId
),

UserReputation AS (
    SELECT 
        u.Id,
        u.Reputation,
        CASE 
            WHEN u.Reputation > 1000 THEN 'High'
            WHEN u.Reputation BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low' 
        END AS ReputationCategory
    FROM 
        Users u
)

SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ur.ReputationCategory,
    ra.LastModificationDate,
    CASE 
        WHEN ra.LastModificationDate IS NULL THEN 'Never Modified'
        ELSE 'Modified Recently'
    END AS ModificationStatus
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.Id
LEFT JOIN 
    RecentActivity ra ON rp.PostId = ra.PostId
WHERE 
    (rp.RankScore <= 3 OR ur.ReputationCategory = 'High')
    AND (rp.ViewCount > 100 OR ur.ReputationCategory = 'Medium')
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;