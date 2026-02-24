
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(vb.VoteCount, 0)) AS TotalVotes,
        SUM(COALESCE(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END, 0)) AS TotalBadges,
        MAX(u.CreationDate) AS AccountCreationDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            v.UserId, 
            COUNT(*) AS VoteCount
        FROM 
            Votes v
        GROUP BY 
            v.UserId
    ) vb ON u.Id = vb.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.CreationDate
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        SUM(COALESCE(CASE WHEN v.Id IS NOT NULL THEN 1 ELSE 0 END, 0)) AS TotalVotes,
        SUM(COALESCE(p.FavoriteCount, 0)) AS TotalFavorites,
        MAX(p.LastActivityDate) AS LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, pt.Name
)
SELECT 
    us.UserId,
    us.Reputation,
    us.PostCount,
    us.TotalVotes AS UserTotalVotes,
    us.TotalBadges,
    ps.PostId,
    ps.PostType,
    ps.CommentCount,
    ps.TotalVotes AS PostTotalVotes,
    ps.TotalFavorites,
    us.AccountCreationDate
FROM 
    UserStats us
JOIN 
    PostStats ps ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId LIMIT 1)
ORDER BY 
    us.Reputation DESC, ps.TotalVotes DESC;
