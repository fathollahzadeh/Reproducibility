
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        pt.Name AS PostType,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUser AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.TotalBounty,
        ua.TotalUpvotes,
        DENSE_RANK() OVER(ORDER BY ua.TotalPosts DESC, ua.TotalBounty DESC) AS UserRank
    FROM 
        UserActivity ua
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.PostType,
    tu.DisplayName AS UserName,
    tu.UserRank,
    CASE 
        WHEN rp.UserPostRank = 1 THEN 'Most Recent Post'
        ELSE 'Older Post'
    END AS PostStatus,
    COALESCE(b.Name, 'No Badge') AS BadgeName
FROM 
    RankedPosts rp
LEFT JOIN 
    TopUser tu ON rp.OwnerUserId = tu.UserId
LEFT JOIN 
    Badges b ON tu.UserId = b.UserId AND b.Date = (SELECT MAX(b2.Date) FROM Badges b2 WHERE b2.UserId = tu.UserId)
WHERE 
    tu.UserRank <= 10
ORDER BY 
    rp.CreationDate DESC,
    tu.TotalUpvotes DESC;
