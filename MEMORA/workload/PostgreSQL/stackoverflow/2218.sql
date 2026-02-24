
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
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
    WHERE 
        u.Reputation > 1000
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
        ur.PostCount >= 5
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        ph.Text AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
),
AggregatedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        tp.UserId,
        CASE 
            WHEN tp.UserId IS NULL THEN 'No Active Users'
            ELSE 'Active User'
        END AS UserStatus,
        COALESCE(cp.CloseReason, 'Not Closed') AS CloseReason
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TopUsers tp ON rp.PostId IN (SELECT r.PostId FROM RankedPosts r WHERE r.PostRank = 1)
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    ad.PostId,
    ad.Title,
    ad.CreationDate,
    ad.Score,
    ad.UserStatus,
    ad.CloseReason,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = ad.PostId) AS CommentCount
FROM 
    AggregatedData ad
WHERE 
    ad.Score > 10 
    AND ad.CloseReason IS NULL 
ORDER BY 
    ad.CreationDate DESC
LIMIT 100;
