WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 8 THEN 1 ELSE 0 END) AS BountyStartCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 8 THEN 1 ELSE 0 END) AS BountyStartCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.BadgeCount,
    us.UpVoteCount AS TotalUpVotes,
    us.DownVoteCount AS TotalDownVotes,
    us.BountyStartCount AS TotalBountyStarts,
    ps.PostId,
    ps.Title AS PostTitle,
    ps.CommentCount AS TotalComments,
    ps.UpVoteCount AS PostUpVotes,
    ps.DownVoteCount AS PostDownVotes,
    ps.BountyStartCount AS PostBountyStarts
FROM 
    UserStatistics us
JOIN 
    PostStatistics ps ON us.UserId = ps.OwnerUserId
ORDER BY 
    us.BadgeCount DESC, 
    ps.CommentCount DESC
LIMIT 100;