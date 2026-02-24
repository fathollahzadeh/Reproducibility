WITH PostData AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        p.ClosedDate,
        u.Reputation,
        u.CreationDate AS UserCreationDate,
        bt.Name AS BadgeName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges bt ON u.Id = bt.UserId 
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
),
VoteData AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    pd.PostId,
    pd.PostTypeId,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.FavoriteCount,
    pd.ClosedDate,
    pd.Reputation,
    pd.UserCreationDate,
    vd.UpVotes,
    vd.DownVotes,
    pd.BadgeName
FROM 
    PostData pd
LEFT JOIN 
    VoteData vd ON pd.PostId = vd.PostId
ORDER BY 
    pd.CreationDate DESC;