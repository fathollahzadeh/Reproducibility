WITH UserPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate AS PostCreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        p.Title,
        u.Reputation AS UserReputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
),
PostInteractions AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    up.PostId,
    up.Title,
    up.UserReputation,
    up.PostCreationDate,
    up.LastActivityDate,
    pi.CommentCount,
    pi.UpVotes,
    pi.DownVotes,
    up.Score,
    up.ViewCount,
    up.AnswerCount,
    up.FavoriteCount
FROM 
    UserPosts up
JOIN 
    PostInteractions pi ON up.PostId = pi.PostId
ORDER BY 
    up.LastActivityDate DESC
LIMIT 100;