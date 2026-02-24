
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Pos
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= DATE '2024-10-01' - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(rp.Upvotes) AS TotalUpvotes,
        SUM(rp.Downvotes) AS TotalDownvotes,
        COUNT(rp.PostId) AS PostCount
    FROM Users u
    JOIN RecentPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY u.Id, u.DisplayName
    HAVING COUNT(rp.PostId) > 5
    ORDER BY TotalUpvotes DESC
    LIMIT 10
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalUpvotes,
    u.TotalDownvotes,
    u.PostCount,
    COALESCE(rp.Title, 'No Title') AS RecentlyPostedTitle,
    rp.CreationDate AS RecentPostDate,
    CASE 
        WHEN rp.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments'
    END AS CommentStatus
FROM TopUsers u
LEFT JOIN RecentPosts rp ON u.UserId = rp.OwnerUserId AND rp.Pos = 1
ORDER BY u.TotalUpvotes DESC;
