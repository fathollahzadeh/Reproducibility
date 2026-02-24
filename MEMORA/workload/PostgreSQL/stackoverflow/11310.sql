WITH AggregatedPostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        MAX(COALESCE(p.LastEditDate, p.CreationDate)) AS LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.PostTypeId
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostsCount,
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
    aps.PostId,
    aps.PostTypeId,
    aps.CommentCount,
    aps.VoteCount,
    aps.UpVoteCount,
    aps.DownVoteCount,
    ue.UserId,
    ue.PostsCount,
    ue.TotalUpVotes,
    ue.TotalDownVotes,
    ue.LastAccess
FROM 
    AggregatedPostStats aps
JOIN 
    Users u ON aps.PostId = u.Id
JOIN 
    UserEngagement ue ON u.Id = ue.UserId
ORDER BY 
    aps.PostId;