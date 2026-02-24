
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        MAX(p.LastActivityDate) AS LastActivityDate,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate)) AS PostAgeInSeconds
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.PostTypeId
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.PostTypeId,
        ps.CommentCount,
        ps.VoteCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.PostAgeInSeconds,
        ROW_NUMBER() OVER (ORDER BY ps.VoteCount DESC, ps.LastActivityDate DESC) AS Rank
    FROM 
        PostStats ps
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.PostTypeId,
    tp.CommentCount,
    tp.VoteCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    tp.PostAgeInSeconds
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 10;
