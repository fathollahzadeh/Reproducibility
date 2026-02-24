
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation, u.CreationDate
),
PostStats AS (
    SELECT
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.PostTypeId
)
SELECT 
    us.UserId,
    us.Reputation,
    us.CreationDate,
    us.PostCount,
    us.CommentCount,
    us.TotalBounties,
    ps.PostId,
    ps.PostTypeId,
    ps.TotalComments,
    ps.Upvotes,
    ps.Downvotes
FROM 
    UserStats us
JOIN 
    PostStats ps ON us.UserId = ps.PostId
ORDER BY 
    us.Reputation DESC, ps.Upvotes DESC;
