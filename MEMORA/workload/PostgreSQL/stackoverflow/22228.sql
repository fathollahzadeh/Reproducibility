
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        SUM(v.BountyAmount) AS TotalBounties,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(DISTINCT ph.UserId) AS EditorCount,
        ARRAY_AGG(DISTINCT ph.Comment) AS Comments,
        SUM(CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 
            ELSE 0 END) AS ClosureEvents
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ur.TotalBounties,
        ur.BadgeCount,
        DENSE_RANK() OVER (ORDER BY ur.Reputation DESC) AS Rank
    FROM 
        UserReputation ur
    WHERE 
        ur.Reputation IS NOT NULL
        AND ur.BadgeCount > 0
),
FilteredPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.AcceptedAnswerId, 
        p.CreationDate,
        COALESCE(phc.ClosureEvents, 0) AS ClosureCount,
        p.Tags,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistoryAggregates phc ON p.Id = phc.PostId
    WHERE 
        p.ViewCount > 1000 
        AND (p.Score > 0 OR p.AcceptedAnswerId IS NOT NULL)
)
SELECT 
    f.Title,
    f.CommentCount,
    f.ClosureCount,
    u.DisplayName AS TopUser,
    u.Reputation AS TopUserReputation
FROM 
    FilteredPosts f
LEFT JOIN 
    (SELECT p.Id, u.DisplayName, u.Reputation
     FROM Posts p
     JOIN Users u ON p.OwnerUserId = u.Id
     JOIN TopUsers tu ON u.Id = tu.UserId
     ORDER BY p.ViewCount DESC) u ON f.Id = u.Id
WHERE 
    f.ClosureCount = 0 
ORDER BY 
    f.CommentCount DESC, 
    f.ClosureCount ASC
LIMIT 10;
