WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - interval '1 year'
    GROUP BY 
        p.Id
), UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
), ActiveUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalBounties,
        ua.TotalUpvotes,
        ua.TotalDownvotes,
        RANK() OVER (ORDER BY ua.TotalUpvotes DESC) AS UpvoteRank
    FROM 
        UserActivity ua
    WHERE 
        ua.TotalUpvotes > 0
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    COALESCE(au.DisplayName, 'No active user') AS ActiveUserName,
    COALESCE(au.TotalBounties, 0) AS ActiveUserTotalBounties,
    RANK() OVER (ORDER BY rp.Score DESC) AS OverallRank,
    CASE 
        WHEN rp.Rank = 1 THEN 'Top Post'
        WHEN rp.Rank BETWEEN 2 AND 5 THEN 'High Performer'
        ELSE 'Standard Post'
    END AS PostCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    ActiveUsers au ON rp.PostId IN (
        SELECT 
            pl.RelatedPostId 
        FROM 
            PostLinks pl 
        WHERE 
            pl.PostId = rp.PostId
    )
WHERE 
    rp.CommentCount > 0 OR au.TotalBounties > 0
ORDER BY 
    OverallRank, rp.CreationDate DESC;