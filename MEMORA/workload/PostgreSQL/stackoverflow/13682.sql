WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        MAX(p.LastActivityDate) AS LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(pm.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(pm.Score, 0)) AS TotalScore,
        SUM(COALESCE(pm.CommentCount, 0)) AS TotalComments,
        SUM(COALESCE(pm.VoteCount, 0)) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostMetrics pm ON p.Id = pm.PostId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    ue.UserId,
    ue.Reputation,
    ue.PostCount,
    ue.TotalViews,
    ue.TotalScore,
    ue.TotalComments,
    ue.TotalVotes,
    RANK() OVER (ORDER BY ue.TotalViews DESC) AS ViewRank,
    RANK() OVER (ORDER BY ue.TotalScore DESC) AS ScoreRank
FROM 
    UserEngagement ue
ORDER BY 
    ue.TotalViews DESC;