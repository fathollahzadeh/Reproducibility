WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.CreationDate,
        p.Title,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, p.CreationDate, p.Title, p.PostTypeId
),
Benchmark AS (
    SELECT 
        PostTypeId,
        COUNT(PostId) AS TotalPosts,
        AVG(CommentCount) AS AvgComments,
        AVG(VoteCount) AS AvgVotes,
        AVG(UpVotes) AS AvgUpVotes,
        AVG(DownVotes) AS AvgDownVotes,
        AVG(BadgeCount) AS AvgBadges
    FROM 
        PostStats
    GROUP BY 
        PostTypeId
)
SELECT 
    pt.Name AS PostType,
    b.TotalPosts,
    b.AvgComments,
    b.AvgVotes,
    b.AvgUpVotes,
    b.AvgDownVotes,
    b.AvgBadges
FROM 
    Benchmark b
JOIN 
    PostTypes pt ON b.PostTypeId = pt.Id
ORDER BY 
    b.TotalPosts DESC;
