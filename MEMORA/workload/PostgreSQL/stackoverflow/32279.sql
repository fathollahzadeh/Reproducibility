
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
ActiveUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.PostCount,
        us.TotalBadges,
        rp.PostTitle,
        rp.PostId,
        rp.Rank
    FROM 
        UserStats us
    JOIN 
        RankedPosts rp ON us.UserId = rp.OwnerUserId
    WHERE 
        rp.Rank = 1
)
SELECT 
    au.UserId,
    au.DisplayName,
    au.Reputation,
    au.PostCount,
    au.TotalBadges,
    COALESCE(p.Score, 0) AS TopPostScore,
    COALESCE(p.ViewCount, 0) AS TopPostViews,
    COUNT(DISTINCT c.Id) AS TotalComments
FROM 
    ActiveUsers au
LEFT JOIN 
    Posts p ON au.PostId = p.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    au.UserId, au.DisplayName, au.Reputation, au.PostCount, au.TotalBadges, p.Score, p.ViewCount
HAVING 
    COUNT(DISTINCT c.Id) > 0 OR COALESCE(p.Score, 0) >= 10
ORDER BY 
    au.Reputation DESC, au.PostCount DESC;
