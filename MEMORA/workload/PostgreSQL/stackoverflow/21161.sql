
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.PostTypeId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation > 1000 THEN 'High'
            WHEN u.Reputation BETWEEN 100 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM 
        Users u
),
PostHistoryEntry AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) FILTER (WHERE ph.PostHistoryTypeId = 12) AS LastDeleted,
        MAX(ph.CreationDate) FILTER (WHERE ph.PostHistoryTypeId = 10) AS LastClosed
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalOutput AS (
    SELECT 
        rp.PostId,
        rp.Title,
        ur.ReputationLevel,
        COALESCE(ph.LastDeleted, ph.LastClosed) AS LastActionDate,
        rp.CommentCount
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        PostHistoryEntry ph ON rp.PostId = ph.PostId
    WHERE 
        rp.rn = 1 AND 
        (COALESCE(ph.LastDeleted, ph.LastClosed) IS NOT NULL OR ur.ReputationLevel = 'High') 
)
SELECT 
    fo.Title,
    fo.ReputationLevel,
    fo.LastActionDate,
    CASE 
        WHEN fo.LastActionDate IS NOT NULL THEN 'Active'
        ELSE 'Inactive'
    END AS PostStatus
FROM 
    FinalOutput fo
WHERE 
    fo.CommentCount > 10 
ORDER BY 
    fo.ReputationLevel DESC,
    fo.LastActionDate DESC
LIMIT 100;
