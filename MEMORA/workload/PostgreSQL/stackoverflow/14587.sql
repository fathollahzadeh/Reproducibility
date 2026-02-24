
WITH UserPostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        u.Id AS UserId,
        u.DisplayName AS UserDisplayName,
        COUNT(v.Id) AS VoteCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.Id, u.DisplayName
)

SELECT 
    ups.PostId,
    ups.Title,
    ups.PostCreationDate,
    ups.UserDisplayName,
    ups.VoteCount,
    ups.BadgeCount,
    p.ViewCount,
    p.Score
FROM 
    UserPostStats ups
JOIN 
    Posts p ON ups.PostId = p.Id
ORDER BY 
    ups.VoteCount DESC, p.Score DESC;
