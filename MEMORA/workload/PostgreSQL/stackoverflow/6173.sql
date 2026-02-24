
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.AnswerCount, p.CommentCount, p.CreationDate
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.Score,
        ps.AnswerCount,
        ps.CommentCount,
        ps.CreationDate,
        ps.TotalBounty,
        ps.UpVotes,
        ps.DownVotes,
        RANK() OVER (ORDER BY ps.Score DESC, ps.ViewCount DESC) AS RankScore
    FROM 
        PostStats ps
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.AnswerCount,
    tp.CommentCount,
    tp.CreationDate,
    tp.TotalBounty,
    tp.UpVotes,
    tp.DownVotes,
    pt.Name AS PostTypeName,
    ut.Reputation AS UserReputation,
    ut.DisplayName AS OwnerDisplayName
FROM 
    TopPosts tp
JOIN 
    Posts p ON tp.PostId = p.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users ut ON p.OwnerUserId = ut.Id
WHERE 
    tp.RankScore <= 10 
ORDER BY 
    tp.RankScore;
