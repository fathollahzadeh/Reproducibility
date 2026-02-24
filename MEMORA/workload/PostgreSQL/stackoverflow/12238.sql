WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, p.PostTypeId
),
Summary AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(*) AS TotalPosts,
        AVG(CommentCount) AS AvgComments,
        SUM(VoteCount) AS TotalVotes,
        AVG(UpVoteCount) AS AvgUpVotes,
        AVG(DownVoteCount) AS AvgDownVotes,
        SUM(BadgeCount) AS TotalBadges
    FROM 
        PostStats ps
    JOIN 
        PostTypes pt ON ps.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)
SELECT 
    PostType,
    TotalPosts,
    AvgComments,
    TotalVotes,
    AvgUpVotes,
    AvgDownVotes,
    TotalBadges
FROM 
    Summary
ORDER BY 
    TotalPosts DESC;