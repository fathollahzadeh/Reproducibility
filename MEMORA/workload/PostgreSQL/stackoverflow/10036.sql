WITH UserPostCount AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostVoteCount AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostCommentCount AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)
SELECT
    u.DisplayName,
    u.Reputation,
    up.PostCount,
    pv.VoteCount,
    pc.CommentCount
FROM 
    Users u
JOIN 
    UserPostCount up ON u.Id = up.UserId
LEFT JOIN 
    PostVoteCount pv ON up.UserId = pv.PostId
LEFT JOIN 
    PostCommentCount pc ON up.UserId = pc.PostId
ORDER BY 
    u.Reputation DESC;