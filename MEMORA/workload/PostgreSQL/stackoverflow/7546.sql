
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(COALESCE(rp.Score, 0)) AS TotalScore,
        SUM(COALESCE(rp.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(rp.CommentCount, 0)) AS TotalComments,
        SUM(COALESCE(rp.VoteCount, 0)) AS TotalVotes,
        COUNT(rp.PostId) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalScore,
    us.TotalViews,
    us.TotalComments,
    us.TotalVotes,
    us.PostCount,
    CASE 
        WHEN us.Reputation >= 1000 THEN 'Gold User'
        WHEN us.Reputation >= 500 THEN 'Silver User'
        ELSE 'New User' 
    END AS UserRank
FROM 
    UserStats us
WHERE 
    us.PostCount > 5
ORDER BY 
    us.TotalScore DESC, us.TotalViews DESC
LIMIT 10;
