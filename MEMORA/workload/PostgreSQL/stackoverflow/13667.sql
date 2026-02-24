WITH UsersStats AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        Views,
        UpVotes,
        DownVotes,
        (UpVotes - DownVotes) AS NetVotes
    FROM 
        Users
),
PostsStats AS (
    SELECT 
        p.Id,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        p.OwnerUserId,
        u.Reputation AS OwnerReputation,
        u.Views AS OwnerViews,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
)
SELECT 
    us.Id AS UserId,
    us.Reputation,
    ps.Id AS PostId,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.OwnerReputation,
    ps.OwnerViews,
    ps.TotalComments,
    ps.CreationDate AS PostCreationDate
FROM 
    UsersStats us
JOIN 
    PostsStats ps ON us.Id = ps.OwnerUserId
ORDER BY 
    us.Reputation DESC, ps.Score DESC;