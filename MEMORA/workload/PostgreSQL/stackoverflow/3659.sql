
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.AcceptedAnswerId IS NOT NULL
),
CombinedData AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalUpvotes,
        us.TotalDownvotes,
        us.TotalPosts,
        us.TotalComments,
        pp.PostId,
        pp.Title,
        pp.Score,
        pp.ViewCount
    FROM 
        UserStats us
    LEFT JOIN 
        PopularPosts pp ON us.UserId = pp.OwnerUserId AND pp.PostRank <= 3
)
SELECT 
    cd.DisplayName,
    cd.Reputation,
    cd.TotalPosts,
    cd.TotalComments,
    COALESCE(cd.Title, 'No Posts') AS PostTitle,
    COALESCE(cd.Score, 0) AS PostScore,
    COALESCE(cd.ViewCount, 0) AS PostViewCount
FROM 
    CombinedData cd
ORDER BY 
    cd.Reputation DESC, cd.TotalPosts DESC, cd.UserId
LIMIT 10;
