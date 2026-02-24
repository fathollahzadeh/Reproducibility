WITH PostStats AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Posts.ViewCount,
        COALESCE(Posts.AnswerCount, 0) AS AnswerCount,
        COALESCE(Posts.CommentCount, 0) AS CommentCount,
        COALESCE(Posts.FavoriteCount, 0) AS FavoriteCount,
        COALESCE(Users.Reputation, 0) AS UserReputation
    FROM 
        Posts
    LEFT JOIN 
        Users ON Posts.OwnerUserId = Users.Id
),
VoteStats AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostHistoryStats AS (
    SELECT 
        PostId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory
    GROUP BY 
        PostId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.UserReputation,
    COALESCE(vs.UpVotes, 0) AS TotalUpVotes,
    COALESCE(vs.DownVotes, 0) AS TotalDownVotes,
    COALESCE(phs.EditCount, 0) AS TotalEdits
FROM 
    PostStats ps
LEFT JOIN 
    VoteStats vs ON ps.PostId = vs.PostId
LEFT JOIN 
    PostHistoryStats phs ON ps.PostId = phs.PostId
ORDER BY 
    ps.ViewCount DESC
LIMIT 100;