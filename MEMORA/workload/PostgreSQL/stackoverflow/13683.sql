WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 4 THEN 1 ELSE 0 END) AS OffensiveVoteCount,
        AVG(p.Score) AS AverageScore,
        COUNT(DISTINCT p.Tags) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.PostTypeId, p.OwnerUserId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(ps.PostId) AS TotalPosts,
    SUM(ps.CommentCount) AS TotalComments,
    SUM(ps.UpVoteCount) AS TotalUpVotes,
    SUM(ps.DownVoteCount) AS TotalDownVotes,
    SUM(ps.OffensiveVoteCount) AS TotalOffensiveVotes,
    AVG(ps.AverageScore) AS AveragePostScore,
    SUM(ps.TagCount) AS TotalTagsUsed
FROM 
    Users u
LEFT JOIN 
    PostStats ps ON u.Id = ps.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    TotalPosts DESC;