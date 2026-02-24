WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate
), UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(pm.CommentCount) AS TotalComments,
        SUM(pm.VoteCount) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostMetrics pm ON pm.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ue.UserId,
    ue.DisplayName,
    ue.PostCount,
    ue.TotalComments,
    ue.TotalVotes
FROM 
    UserEngagement ue
ORDER BY 
    ue.PostCount DESC, 
    ue.TotalVotes DESC
LIMIT 50;