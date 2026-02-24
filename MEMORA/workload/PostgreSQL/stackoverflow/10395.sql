WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ups.PostCount,
    ups.CommentCount,
    ups.VoteCount
FROM 
    Users u
LEFT JOIN 
    UserPostStats ups ON u.Id = ups.UserId
ORDER BY 
    ups.PostCount DESC, ups.CommentCount DESC, ups.VoteCount DESC;