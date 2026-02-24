
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.CreationDate IS NOT NULL AND vt.Id = 2 THEN 1 ELSE 0 END) AS UpVoteCount, 
        SUM(CASE WHEN v.CreationDate IS NOT NULL AND vt.Id = 3 THEN 1 ELSE 0 END) AS DownVoteCount 
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(p.Score, 0) AS Score,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(p.FavoriteCount, 0) AS FavoriteCount,
        COALESCE(p.ClosedDate, p.CreationDate) AS CloseDate,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
)
SELECT 
    u.DisplayName,
    ups.PostCount,
    ups.CommentCount,
    ups.UpVoteCount,
    ups.DownVoteCount,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.AnswerCount,
    ps.CommentCount AS PostCommentCount,
    ps.FavoriteCount,
    ps.CloseDate
FROM 
    UserPostStats ups
JOIN 
    Users u ON ups.UserId = u.Id
JOIN 
    PostSummary ps ON u.Id = ps.OwnerUserId
ORDER BY 
    ups.PostCount DESC, 
    ups.UpVoteCount DESC;
