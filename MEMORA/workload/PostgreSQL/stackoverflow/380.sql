WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(b.UserId, 0) AS HasBadge,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName, b.UserId
),

PostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount,
        MIN(ph.CreationDate) AS FirstChange,
        MAX(ph.CreationDate) AS LastChange
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)

SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    rp.Title AS TopPostTitle,
    rp.CreationDate AS PostCreationDate,
    rp.Score AS PostScore,
    ph.HistoryCount AS ChangeFrequency,
    ph.FirstChange AS FirstEditDate,
    ph.LastChange AS LastEditDate,
    CASE 
        WHEN up.Reputation > 1000 THEN 'Active' 
        ELSE 'New User' 
    END AS UserStatus
FROM 
    UserReputation up
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId AND rp.Rank = 1
LEFT JOIN 
    PostHistory ph ON rp.Id = ph.PostId
WHERE 
    up.HasBadge IS NULL
ORDER BY 
    up.Reputation DESC, rp.Score DESC
LIMIT 10;
