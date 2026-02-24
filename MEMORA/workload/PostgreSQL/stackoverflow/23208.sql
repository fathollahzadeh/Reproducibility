
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserEngagement AS (
    SELECT
        u.Id AS UserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,  
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount  
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostBadges AS (
    SELECT 
        p.Id AS PostId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ue.CommentCount, 0) AS CommentCount,
        COALESCE(ue.UpvoteCount, 0) AS UpvoteCount,
        COALESCE(ue.DownvoteCount, 0) AS DownvoteCount
    FROM 
        Users u
    LEFT JOIN 
        UserEngagement ue ON u.Id = ue.UserId
    WHERE 
        u.Reputation > 100
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.Rank,
    a.DisplayName AS ActiveUserName,
    a.CommentCount,
    a.UpvoteCount,
    a.DownvoteCount,
    COALESCE(pb.BadgeCount, 0) AS PostBadgeCount
FROM 
    RankedPosts rp
LEFT JOIN 
    ActiveUsers a ON rp.Score > (SELECT AVG(Score) FROM Posts)
LEFT JOIN 
    PostBadges pb ON rp.PostId = pb.PostId
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.PostId, a.CommentCount DESC;
