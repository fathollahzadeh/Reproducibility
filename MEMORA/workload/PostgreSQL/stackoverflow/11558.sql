
WITH PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ph.UserId AS LastEditedBy,
        ph.CreationDate AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId 
            AND ph.CreationDate = (SELECT MAX(ph2.CreationDate) FROM PostHistory ph2 WHERE ph2.PostId = p.Id)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, ph.UserId, ph.CreationDate
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.VoteCount,
    ps.LastEditedBy,
    ps.LastEditDate,
    us.BadgeCount,
    us.TotalUpVotes,
    us.TotalDownVotes
FROM 
    PostSummary ps
JOIN 
    Users u ON ps.LastEditedBy = u.Id
JOIN 
    UserStats us ON u.Id = us.UserId
ORDER BY 
    ps.CreationDate DESC;
