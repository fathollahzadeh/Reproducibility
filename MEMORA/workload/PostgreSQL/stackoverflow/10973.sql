WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostSummary AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
BadgeSummary AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS TotalBadges, 
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)

SELECT 
    u.UserId, 
    u.DisplayName, 
    u.UpVotes, 
    u.DownVotes, 
    u.TotalVotes, 
    p.PostId, 
    p.Title, 
    p.CreationDate AS PostCreationDate, 
    p.Score AS PostScore, 
    p.ViewCount AS PostViewCount, 
    p.CommentCount AS PostCommentCount, 
    b.TotalBadges AS UserBadgesCount, 
    b.HighestBadgeClass AS UserHighestBadgeClass
FROM 
    UserVoteSummary u
JOIN 
    PostSummary p ON u.UserId = p.PostId  
LEFT JOIN 
    BadgeSummary b ON u.UserId = b.UserId
ORDER BY 
    u.TotalVotes DESC, 
    p.Score DESC
LIMIT 100;