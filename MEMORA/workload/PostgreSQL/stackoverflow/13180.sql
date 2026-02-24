
WITH UserPostCount AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(Id) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(b.Id) AS BadgeCount 
        FROM 
            Badges b 
        GROUP BY 
            UserId
    ) b ON p.OwnerUserId = b.UserId
)
SELECT 
    upc.UserId,
    upc.PostCount,
    upc.TotalUpVotes,
    upc.TotalDownVotes,
    upc.AverageReputation,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.BadgeCount
FROM 
    UserPostCount upc
JOIN 
    PostStats ps ON upc.UserId = ps.OwnerUserId
ORDER BY 
    upc.PostCount DESC, upc.AverageReputation DESC;
