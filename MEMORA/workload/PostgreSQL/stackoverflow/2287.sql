
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVotes, 
        rp.DownVotes,
        p.OwnerUserId
    FROM 
        RankedPosts rp
    JOIN
        Posts p ON rp.PostId = p.Id
    WHERE 
        rp.RN = 1 AND
        rp.CommentCount > 5 AND
        (rp.UpVotes - rp.DownVotes) > 0
),
UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation,
        COUNT(DISTINCT f.PostId) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        FilteredPosts f ON u.Id = f.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    us.UserId, 
    us.DisplayName, 
    us.Reputation, 
    us.TotalPosts,
    COALESCE(MAX(f.UpVotes), 0) AS BestPostUpVotes
FROM 
    UserStats us
LEFT JOIN 
    FilteredPosts f ON us.UserId = f.OwnerUserId
GROUP BY 
    us.UserId, us.DisplayName, us.Reputation, us.TotalPosts
HAVING 
    us.Reputation > 1000
ORDER BY 
    us.TotalPosts DESC, BestPostUpVotes DESC;
