WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(DISTINCT bh.UserId) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Badges bh ON bh.UserId = p.OwnerUserId
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.CommentCount,
        ps.VoteCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.AnswerCount,
        ps.BadgeCount,
        ROW_NUMBER() OVER (ORDER BY ps.VoteCount DESC, ps.CommentCount DESC, ps.UpVoteCount DESC) AS Rank
    FROM 
        PostStats ps
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.OwnerDisplayName,
    p.CreationDate,
    tp.CommentCount,
    tp.VoteCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    tp.AnswerCount,
    tp.BadgeCount
FROM 
    TopPosts tp
JOIN 
    Posts p ON tp.PostId = p.Id
WHERE 
    tp.Rank <= 10
ORDER BY 
    tp.Rank;
