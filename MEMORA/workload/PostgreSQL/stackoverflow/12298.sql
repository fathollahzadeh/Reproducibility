
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(u.UpVotes) AS TotalUps,
        SUM(u.DownVotes) AS TotalDowns
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.CommentCount,
    pd.VoteCount,
    ua.UserId,
    ua.PostCount,
    ua.TotalViews,
    ua.TotalUps,
    ua.TotalDowns
FROM 
    PostDetails pd
JOIN 
    UserActivity ua ON pd.PostId = ua.UserId
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC
LIMIT 100;
