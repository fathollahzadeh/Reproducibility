
WITH PostStats AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Posts.ViewCount,
        Posts.Score,
        Users.Reputation AS OwnerReputation,
        COUNT(DISTINCT Comments.Id) AS CommentCount,
        COUNT(DISTINCT Votes.Id) AS VoteCount
    FROM 
        Posts
    LEFT JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Posts.Id, Posts.Title, Posts.CreationDate, Posts.ViewCount, Posts.Score, Users.Reputation
),
PostHistoryStats AS (
    SELECT 
        PostId,
        COUNT(*) AS HistoryCount,
        MAX(CreationDate) AS LastEdited
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
    ps.Score,
    ps.OwnerReputation,
    ps.CommentCount,
    ps.VoteCount,
    COALESCE(phs.HistoryCount, 0) AS PostHistoryCount,
    phs.LastEdited
FROM 
    PostStats ps
LEFT JOIN 
    PostHistoryStats phs ON ps.PostId = phs.PostId
ORDER BY 
    ps.ViewCount DESC, ps.Score DESC;
