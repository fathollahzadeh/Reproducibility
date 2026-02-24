
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT bh.Id) AS EditHistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory bh ON p.Id = bh.PostId
    GROUP BY 
        p.Id, p.Title
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.VoteCount,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.EditHistoryCount,
        ROW_NUMBER() OVER (ORDER BY ps.VoteCount DESC, ps.CommentCount DESC) AS RowNum
    FROM 
        PostStatistics ps
)
SELECT 
    tp.*
FROM 
    TopPosts tp
WHERE 
    tp.RowNum <= 10;
