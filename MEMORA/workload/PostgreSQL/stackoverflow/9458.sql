
WITH UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Score,
        pd.ViewCount,
        pd.CommentCount,
        pd.AnswerCount,
        RANK() OVER (ORDER BY pd.Score DESC, pd.ViewCount DESC) AS Rank
    FROM 
        PostDetails pd
)
SELECT 
    up.UserId,
    up.TotalVotes,
    up.UpVotes,
    up.DownVotes,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.AnswerCount
FROM 
    UserVoteCounts up
JOIN 
    TopPosts tp ON up.TotalVotes > 0
WHERE 
    tp.Rank <= 10
ORDER BY 
    up.TotalVotes DESC, 
    tp.Score DESC;
