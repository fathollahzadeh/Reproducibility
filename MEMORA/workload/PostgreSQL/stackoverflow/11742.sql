
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(u.UpVotes), 0) AS TotalUpVotes,
        COALESCE(SUM(u.DownVotes), 0) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),

PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        COALESCE(COUNT(c.Id), 0) AS TotalComments,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostCount,
    ua.CommentCount,
    ua.TotalBounty,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    pm.PostId,
    pm.Title AS PostTitle,
    pm.CreationDate AS PostCreationDate,
    pm.ViewCount AS PostViewCount,
    pm.Score AS PostScore,
    pm.AnswerCount AS PostAnswerCount,
    pm.TotalComments AS PostTotalComments,
    pm.TotalUpVotes AS PostTotalUpVotes,
    pm.TotalDownVotes AS PostTotalDownVotes
FROM 
    UserActivity ua
LEFT JOIN 
    PostMetrics pm ON ua.UserId = pm.PostId
ORDER BY 
    ua.PostCount DESC, pm.ViewCount DESC;
