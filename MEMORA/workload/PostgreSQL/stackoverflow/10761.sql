
WITH PostStats AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        COUNT(c.Id) AS CommentCount, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount, 
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2023-01-01' 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, u.DisplayName
), UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(b.Id) AS BadgeCount, 
        SUM(p.ViewCount) AS TotalViewCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.Score,
    ps.ViewCount,
    ps.CreationDate,
    ps.OwnerDisplayName,
    us.UserId,
    us.DisplayName AS UserDisplayName,
    us.BadgeCount,
    us.TotalViewCount
FROM 
    PostStats ps
JOIN 
    UserStats us ON ps.OwnerDisplayName = us.DisplayName
ORDER BY 
    ps.Score DESC, ps.CreationDate DESC
LIMIT 100;
