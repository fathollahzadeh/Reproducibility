
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        RANK() OVER (ORDER BY SUM(COALESCE(p.ViewCount, 0)) DESC) AS ActivityRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY 
        u.Id, u.DisplayName
),
ActiveUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalViews, 
        TotalBounties,
        TotalPosts,
        TotalComments,
        ActivityRank,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC, TotalPosts DESC) AS UserRank
    FROM 
        UserActivity
    WHERE 
        TotalPosts > 0 
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
)
SELECT 
    au.DisplayName AS ActiveUser,
    au.TotalViews,
    au.TotalBounties,
    au.TotalPosts,
    au.TotalComments,
    tp.Title AS TopPostTitle,
    tp.CommentCount AS TopPostComments,
    tp.TotalBounties AS TopPostTotalBounties
FROM 
    ActiveUsers au
LEFT JOIN 
    TopPosts tp ON au.UserId = (SELECT OwnerUserId FROM Posts ORDER BY ViewCount DESC LIMIT 1)
WHERE 
    au.UserRank <= 10 
ORDER BY 
    au.ActivityRank, au.DisplayName;
