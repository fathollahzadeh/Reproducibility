
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        COALESCE(b.Name, 'No Badge') AS UserBadge
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON rp.PostId = b.UserId AND b.Class = 1  
    WHERE 
        rp.PostRank > 1
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN up.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN up.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        AVG(p.Score) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes up ON p.Id = up.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.CommentCount,
    us.DisplayName AS PostOwner,
    us.TotalUpvotes,
    us.TotalDownvotes,
    us.TotalPosts,
    us.AvgScore,
    CASE 
        WHEN fp.UserBadge = 'No Badge' AND us.TotalPosts = 0 THEN 'New User'
        ELSE 'Active User'
    END AS UserCategory
FROM 
    FilteredPosts fp
JOIN 
    UserStats us ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = fp.PostId)
WHERE 
    fp.CommentCount >= 2
    AND (us.TotalUpvotes - us.TotalDownvotes) > 5
ORDER BY 
    fp.CreationDate DESC
LIMIT 100;
