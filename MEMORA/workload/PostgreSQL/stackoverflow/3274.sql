
WITH User_reputation AS (
    SELECT 
        u.Id, 
        u.DisplayName, 
        u.Reputation, 
        (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id) AS PostCount,
        COALESCE((SELECT AVG(v.BountyAmount) FROM Votes v WHERE v.UserId = u.Id AND v.VoteTypeId IN (8, 9)), 0) AS AverageBounty,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COUNT(c.Id) FILTER(WHERE c.Text IS NOT NULL) AS NonNullCommentCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.Body, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount
),
TopPosts AS (
    SELECT 
        pm.*, 
        ROW_NUMBER() OVER (ORDER BY pm.Score DESC, pm.ViewCount DESC) AS PostRank
    FROM 
        PostMetrics pm
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    COALESCE(tp.Title, 'No Posts') AS PostTitle,
    tp.Score AS PostScore,
    tp.ViewCount AS PostViews,
    tp.LastEditDate,
    CASE 
        WHEN tp.PostRank <= 10 THEN 'Top Performers'
        ELSE 'Others'
    END AS UserGroup
FROM 
    User_reputation u
LEFT JOIN 
    TopPosts tp ON u.Id = tp.PostId
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users)
    AND (tp.PostId IS NOT NULL OR (tp.PostId IS NULL AND tp.NonNullCommentCount > 0))
ORDER BY 
    u.Reputation DESC, 
    tp.Score DESC NULLS LAST;
