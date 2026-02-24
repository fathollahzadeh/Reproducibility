WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT v.UserId) AS UniqueVoters,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        p.Id, p.PostTypeId, p.CreationDate
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        SUM(u.Views) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    p.PostId,
    p.PostTypeId,
    p.CreationDate,
    p.CommentCount,
    p.UpVotes,
    p.DownVotes,
    p.UniqueVoters,
    p.AverageReputation,
    u.UserId,
    u.BadgeCount,
    u.TotalUpVotes,
    u.TotalDownVotes,
    u.TotalViews
FROM 
    PostStats p
JOIN 
    UserStats u ON p.PostId = u.UserId
ORDER BY 
    p.CommentCount DESC, 
    p.UpVotes DESC;