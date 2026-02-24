
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(co.FavoriteCount, 0) AS FavoriteCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS FavoriteCount
        FROM 
            Votes
        WHERE 
            VoteTypeId = 5  
        GROUP BY 
            PostId
    ) co ON p.Id = co.PostId
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
        rp.FavoriteCount,
        rp.OwnerUserId
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5  
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(fp.CommentCount) AS TotalComments,
        SUM(fp.FavoriteCount) AS TotalFavorites,
        COUNT(fp.PostId) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        FilteredPosts fp ON u.Id = fp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        SUM(fp.CommentCount) > 10 OR 
        SUM(fp.FavoriteCount) > 10       
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalComments,
    us.TotalFavorites,
    us.TotalPosts,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
FROM 
    UserStatistics us
LEFT JOIN 
    Votes v ON us.UserId = v.UserId
WHERE 
    v.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'  
GROUP BY 
    us.UserId, us.DisplayName, us.Reputation, us.TotalComments, us.TotalFavorites, us.TotalPosts
ORDER BY 
    us.Reputation DESC, us.TotalFavorites DESC
LIMIT 10;
