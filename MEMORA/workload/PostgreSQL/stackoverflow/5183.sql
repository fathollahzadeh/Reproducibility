
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
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
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT v.UserId) AS VoterCount,
        p.CreationDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.VoterCount,
        ROW_NUMBER() OVER (ORDER BY ps.UpVotes DESC, ps.CommentCount DESC) AS Rank
    FROM 
        PostStats ps
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.UpVotes AS UserUpVotes,
    t.DownVotes AS UserDownVotes,
    p.Title AS PostTitle,
    p.CommentCount AS PostCommentCount,
    p.UpVotes AS PostUpVotes,
    p.DownVotes AS PostDownVotes
FROM 
    UserVoteStats t
JOIN 
    TopPosts p ON t.UpVotes > 0 OR t.DownVotes > 0
WHERE 
    t.TotalVotes > 10
    AND p.Rank <= 10
ORDER BY 
    t.UpVotes DESC, p.UpVotes DESC;
