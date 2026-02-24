WITH RecentPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount,
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    tu.DisplayName AS OwnerDisplayName,
    tu.Reputation,
    CASE 
        WHEN rp.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments'
    END AS CommentStatus,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = rp.Id 
     AND v.VoteTypeId = 2) AS UpVoteCount,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = rp.Id 
     AND v.VoteTypeId = 3) AS DownVoteCount
FROM 
    RecentPosts rp
JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.Id
WHERE 
    rp.OwnerPostRank = 1
ORDER BY 
    rp.CreationDate DESC
LIMIT 10;