WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownvoteCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
),

ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(u.UpVotes, 0) - COALESCE(u.DownVotes, 0) AS NetVotes,
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.CreationDate < cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        u.Id
),

UserComments AS (
    SELECT 
        c.UserId,
        COUNT(*) AS CommentCount,
        STRING_AGG(c.Text, ', ') AS CommentTexts
    FROM 
        Comments c
    JOIN 
        Posts p ON c.PostId = p.Id
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '6 months'
    GROUP BY 
        c.UserId
)

SELECT 
    au.UserId,
    au.DisplayName,
    au.Reputation,
    au.NetVotes,
    au.PostsCount,
    COALESCE(uc.CommentCount, 0) AS TotalComments,
    COALESCE(uc.CommentTexts, 'No comments') AS LastComments,
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.RankScore,
    rp.UpvoteCount,
    rp.DownvoteCount
FROM 
    ActiveUsers au
LEFT JOIN 
    UserComments uc ON au.UserId = uc.UserId
LEFT JOIN 
    RankedPosts rp ON au.PostsCount > 0 
                     AND rp.RankScore <= 10 
                     AND rp.ViewCount > 50
WHERE 
    (au.Reputation > 1000 AND uc.CommentCount IS NOT NULL)
    OR (au.Reputation <= 1000 AND uc.CommentCount IS NOT NULL AND uc.CommentCount > 5)
ORDER BY 
    au.Reputation DESC,
    rp.ViewCount DESC
LIMIT 50;