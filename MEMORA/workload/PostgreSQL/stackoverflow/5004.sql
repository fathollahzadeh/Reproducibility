WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
    HAVING 
        COUNT(c.Id) > 0 AND p.Score > 10
)
SELECT 
    ur.DisplayName AS UserName, 
    ur.Reputation, 
    ur.PostCount, 
    ur.TotalBounties, 
    tp.Title AS TopPostTitle, 
    tp.Score AS PostScore, 
    tp.ViewCount AS PostViewCount, 
    tp.CommentCount AS RelatedCommentCount
FROM 
    UserReputation ur
JOIN 
    TopPosts tp ON ur.UserId = tp.PostId 
ORDER BY 
    ur.Reputation DESC, 
    tp.Score DESC
LIMIT 10;