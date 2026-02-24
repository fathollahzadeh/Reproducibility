
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0 
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        us.DisplayName,
        us.Reputation,
        us.TotalBounties,
        us.TotalUpvotes,
        us.TotalDownvotes,
        CASE 
            WHEN us.Reputation >= 1000 THEN 'High Repute' 
            WHEN us.Reputation >= 500 THEN 'Medium Repute'
            ELSE 'Low Repute'
        END AS UserReputationCategory
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
    WHERE 
        rp.Rank = 1
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.DisplayName,
    pd.Reputation,
    pd.TotalBounties,
    pd.TotalUpvotes,
    pd.TotalDownvotes,
    pd.UserReputationCategory,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = pd.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pd.PostId AND v.VoteTypeId = 2) AS UpvoteCount,
    CASE 
        WHEN pd.Score >= 10 THEN 'Popular'
        WHEN pd.Score BETWEEN 1 AND 9 THEN 'Moderately Popular'
        ELSE 'Unpopular'
    END AS PopularityCategory
FROM 
    PostDetails pd
WHERE 
    pd.TotalBounties > 0 OR pd.TotalUpvotes > 0
ORDER BY 
    pd.Score DESC, pd.CreationDate ASC
LIMIT 100;
