WITH PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score AS PostScore,
        p.ViewCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Id = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN vt.Id = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.FavoriteCount
)

SELECT 
    PostId,
    Title,
    CreationDate,
    PostScore,
    ViewCount,
    VoteCount,
    UpVoteCount,
    DownVoteCount,
    AnswerCount,
    CommentCount,
    FavoriteCount
FROM 
    PostVoteStats
ORDER BY 
    PostScore DESC, 
    ViewCount DESC
LIMIT 100;