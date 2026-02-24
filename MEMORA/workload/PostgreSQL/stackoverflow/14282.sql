
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS DownVotesCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pt.Name AS PostType,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, pt.Name
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostCount,
    ua.UpVotesCount,
    ua.DownVotesCount,
    ua.BadgeCount,
    ua.CommentCount,
    ps.PostId,
    ps.Title,
    ps.PostType,
    ps.CommentCount AS PostCommentCount,
    ps.VoteCount AS PostVoteCount
FROM 
    UserActivity ua
JOIN 
    PostSummary ps ON ua.UserId = ps.PostId  
ORDER BY 
    ua.BadgeCount DESC
LIMIT 100;
