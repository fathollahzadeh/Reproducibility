
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.Reputation) AS TotalReputation,
        RANK() OVER (ORDER BY SUM(u.Reputation) DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '2 years'
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalReputation,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    CASE 
        WHEN rp.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments'
    END AS CommentStatus,
    COALESCE(
        (SELECT STRING_AGG(pt.Name, ',' ORDER BY pt.Name)
         FROM PostHistory ph 
         JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
         WHERE ph.PostId = rp.Id
         AND ph.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'), 
        'No Recent History') AS RecentPostHistory
FROM 
    TopUsers tu
JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tu.TotalReputation DESC, rp.CreationDate DESC
LIMIT 50;
