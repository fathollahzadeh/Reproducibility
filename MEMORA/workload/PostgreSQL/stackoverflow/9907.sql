
WITH UserVoteAggregates AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ua.TotalUpvotes - ua.TotalDownvotes AS NetVotes
    FROM 
        Users u
    JOIN 
        UserVoteAggregates ua ON u.Id = ua.UserId
    WHERE 
        ua.TotalVotes > 0
    ORDER BY 
        NetVotes DESC
    LIMIT 10
),
PostWithTopUsers AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.ViewCount,
        ps.CommentCount,
        ps.UpvoteCount,
        ps.DownvoteCount,
        tu.UserId AS TopUserId,
        tu.DisplayName AS TopUserName
    FROM 
        PostStatistics ps
    JOIN 
        Votes v ON ps.PostId = v.PostId
    JOIN 
        TopUsers tu ON v.UserId = tu.UserId
    WHERE 
        ps.UpvoteCount > 0
)
SELECT 
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    p.Score AS PostScore,
    p.ViewCount AS PostViewCount,
    p.CommentCount AS PostCommentCount,
    p.UpvoteCount AS PostUpvoteCount,
    p.DownvoteCount AS PostDownvoteCount,
    p.TopUserName,
    COUNT(DISTINCT c.Id) AS TotalComments
FROM 
    PostWithTopUsers p
LEFT JOIN 
    Comments c ON p.PostId = c.PostId
GROUP BY 
    p.PostId, p.Title, p.CreationDate, p.Score, p.ViewCount, 
    p.CommentCount, p.UpvoteCount, p.DownvoteCount, p.TopUserName
ORDER BY 
    p.Score DESC, p.ViewCount DESC;
