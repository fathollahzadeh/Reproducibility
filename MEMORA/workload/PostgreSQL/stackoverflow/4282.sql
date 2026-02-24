WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS NumberOfPosts,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.NumberOfPosts,
        ua.TotalCommentScore,
        ua.UpvoteCount,
        ua.DownvoteCount,
        ROW_NUMBER() OVER (ORDER BY ua.Reputation DESC) AS rank
    FROM 
        UserActivity ua
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.NumberOfPosts,
    tu.TotalCommentScore,
    tu.UpvoteCount,
    tu.DownvoteCount,
    COALESCE(rp.Title, 'No Recent Posts') AS RecentPostTitle
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.PostId
WHERE 
    tu.rank <= 10
ORDER BY 
    tu.Reputation DESC, 
    tu.NumberOfPosts DESC
OFFSET 5 ROWS
FETCH NEXT 5 ROWS ONLY;