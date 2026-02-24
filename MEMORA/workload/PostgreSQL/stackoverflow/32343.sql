
WITH RECURSIVE PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        1 AS Level,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
    AND 
        p.Score > 10

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        pp.Level + 1,
        p.OwnerUserId
    FROM 
        Posts p
    INNER JOIN 
        PopularPosts pp ON p.AcceptedAnswerId = pp.Id
    WHERE 
        p.PostTypeId = 2 
)

, UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalBounties,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    pp.Title AS PopularPostTitle,
    pp.ViewCount AS PopularPostViews,
    pp.Score AS PopularPostScore,
    pp.CreationDate AS PopularPostDate,
    CASE 
        WHEN ua.TotalPosts > 0 THEN ROUND((ua.TotalUpVotes * 1.0 / NULLIF(ua.TotalPosts, 0)), 2)
        ELSE 0 
    END AS UpvoteRatio,
    CASE 
        WHEN ua.TotalPosts > 0 THEN ROUND((ua.TotalDownVotes * 1.0 / NULLIF(ua.TotalPosts, 0)), 2)
        ELSE 0 
    END AS DownvoteRatio
FROM 
    UserActivity ua
LEFT JOIN 
    PopularPosts pp ON ua.UserId = pp.OwnerUserId
ORDER BY 
    ua.TotalPosts DESC,    
    pp.Score DESC          
LIMIT 10;
