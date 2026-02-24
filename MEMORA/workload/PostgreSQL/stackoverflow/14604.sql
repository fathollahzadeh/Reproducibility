
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= DATE '2023-01-01'
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, p.CreationDate
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.PostTypeId,
    ps.CreationDate,
    ps.VoteCount,
    ps.CommentCount,
    ps.BadgeCount,
    ps.Upvotes,
    ps.Downvotes,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation
FROM 
    PostStats ps
JOIN 
    Users u ON ps.PostId = u.Id
ORDER BY 
    ps.CreationDate DESC;
