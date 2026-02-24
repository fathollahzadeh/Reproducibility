WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS TotalComments,
        AVG(v.BountyAmount) AS AverageBounty
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'  
    GROUP BY 
        p.Id, u.DisplayName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.ViewCount,
    pm.Score,
    pm.AnswerCount,
    pm.CommentCount,
    pm.TotalComments,
    pm.AverageBounty,
    ur.DisplayName AS UserName,
    ur.Reputation,
    ur.BadgeCount
FROM 
    PostMetrics pm
JOIN 
    UserReputation ur ON pm.OwnerDisplayName = ur.DisplayName
ORDER BY 
    pm.Score DESC, pm.ViewCount DESC;