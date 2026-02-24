
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year' 
        AND p.Score > 0
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostsWithComments AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        p.Title
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
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.BadgeCount,
    us.UpVotes,
    us.DownVotes,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    pwc.CommentCount,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Top Post'
        ELSE 'Regular Post' 
    END AS PostCategory
FROM 
    UserStatistics us
JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
LEFT JOIN 
    PostsWithComments pwc ON rp.PostId = pwc.PostId
WHERE 
    us.BadgeCount > 0
ORDER BY 
    us.DisplayName, rp.Score DESC
LIMIT 100;
