
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
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
        p.Id, p.PostTypeId
),
PostTypeCounts AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(CommentCount) AS TotalComments,
        SUM(VoteCount) AS TotalVotes,
        SUM(UpVoteCount) AS TotalUpVotes,
        SUM(DownVoteCount) AS TotalDownVotes,
        SUM(BadgeCount) AS TotalBadges
    FROM 
        PostStats
    GROUP BY 
        PostTypeId
)
SELECT 
    pt.Name AS PostTypeName,
    ptc.TotalPosts,
    ptc.TotalComments,
    ptc.TotalVotes,
    ptc.TotalUpVotes,
    ptc.TotalDownVotes,
    ptc.TotalBadges
FROM 
    PostTypes pt
JOIN 
    PostTypeCounts ptc ON pt.Id = ptc.PostTypeId
ORDER BY 
    ptc.TotalPosts DESC;
