
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS VoteBalance
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
), 
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS VoteDifference
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
), 
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        vs.TotalVotes,
        vs.UpVotes,
        vs.DownVotes,
        ROW_NUMBER() OVER (ORDER BY vs.VoteBalance DESC) AS Rank
    FROM 
        UserVoteStats vs
    JOIN 
        Users u ON vs.UserId = u.Id
    WHERE 
        vs.TotalVotes > 0
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.ViewCount,
        ps.CommentCount,
        ps.VoteDifference,
        ROW_NUMBER() OVER (ORDER BY ps.VoteDifference DESC) AS Rank
    FROM 
        PostStats ps
    WHERE 
        ps.VoteDifference >= 0
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.TotalVotes AS UserVoteCount,
    tp.Title AS TopPostTitle,
    tp.Score AS PostScore,
    tp.ViewCount AS PostViews,
    tp.CommentCount AS PostComments
FROM 
    TopUsers tu
JOIN 
    TopPosts tp ON tu.Rank = tp.Rank
WHERE 
    tu.Rank <= 10 AND tp.Rank <= 10
ORDER BY 
    tu.Rank, tp.Rank;
