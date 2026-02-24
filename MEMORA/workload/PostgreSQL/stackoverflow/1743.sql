
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rnk
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN p.Id IS NOT NULL THEN 1 ELSE 0 END) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostWithComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(c.Score), 0) AS TotalCommentScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.BadgeCount,
    us.PostCount,
    us.UpvoteCount,
    rp.Title,
    rp.CreationDate,
    pwc.CommentCount,
    pwc.TotalCommentScore
FROM 
    UserStats us
JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.Rnk = 1
LEFT JOIN 
    PostWithComments pwc ON rp.PostId = pwc.PostId
WHERE 
    us.BadgeCount > 0 AND 
    (us.PostCount > 5 OR us.UpvoteCount > 10)
ORDER BY 
    us.UpvoteCount DESC, us.PostCount DESC;
