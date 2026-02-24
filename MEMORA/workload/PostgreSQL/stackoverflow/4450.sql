WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.VoteTypeId = 8 
    GROUP BY 
        u.Id, u.Reputation
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
)
SELECT 
    up.DisplayName,
    up.Reputation,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(recent.EditRank, 0) AS RecentEditRank,
    COALESCE(ub.QuestionCount, 0) AS UserQuestionCount,
    COALESCE(ub.TotalBounty, 0) AS TotalBounty
FROM 
    Users up
LEFT JOIN 
    UserReputation ub ON up.Id = ub.UserId
LEFT JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    RecentEdits recent ON rp.Id = recent.PostId AND recent.EditRank = 1
WHERE 
    up.Reputation > 1000 
ORDER BY 
    rp.Score DESC, up.DisplayName ASC;