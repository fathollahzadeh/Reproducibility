WITH PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(CASE WHEN ph.PostId IS NOT NULL THEN ph.CreationDate END) AS LastHistoryChange
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.PostTypeId, p.Score, p.ViewCount
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        MAX(u.LastAccessDate) AS LastAccess
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)

SELECT 
    pa.PostId,
    pa.PostTypeId,
    pa.Score,
    pa.ViewCount,
    pa.CommentCount,
    pa.VoteCount,
    pa.BadgeCount,
    pa.LastHistoryChange,
    ua.UserId,
    ua.PostCount,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    ua.LastAccess
FROM 
    PostActivity pa
JOIN 
    UserActivity ua ON pa.PostTypeId = 1 AND pa.PostId = (SELECT MAX(p.Id) FROM Posts p WHERE p.OwnerUserId = ua.UserId)
ORDER BY 
    pa.LastHistoryChange DESC;