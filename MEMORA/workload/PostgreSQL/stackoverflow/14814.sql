WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.OwnerUserId, p.Score, p.ViewCount
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(ps.Score) AS TotalScore,
        SUM(ps.ViewCount) AS TotalViews,
        SUM(ps.CommentCount) AS TotalComments,
        SUM(ps.AnswerCount) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    u.UserId,
    u.Reputation,
    u.BadgeCount,
    u.TotalScore,
    u.TotalViews,
    u.TotalComments,
    u.TotalAnswers
FROM 
    UserStats u
ORDER BY 
    u.TotalScore DESC, u.Reputation DESC;