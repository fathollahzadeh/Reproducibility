
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COALESCE(SUM(p1.Score), 0) AS AnswerScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        Posts p1 ON p.Id = p1.ParentId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.VoteCount,
    ps.BadgeCount,
    ps.AnswerScore,
    CASE 
        WHEN ps.Score > 100 THEN 'High Scoring'
        WHEN ps.Score BETWEEN 50 AND 100 THEN 'Moderate Scoring'
        ELSE 'Low Scoring'
    END AS ScoreCategory
FROM 
    PostStats ps
ORDER BY 
    ps.ViewCount DESC, ps.Score DESC;
