WITH PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount,
        COALESCE(a.Count, 0) AS AnswerCount,
        COALESCE(b.Count, 0) AS BadgesCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        (SELECT 
             ParentId, 
             COUNT(*) AS Count 
         FROM 
             Posts 
         WHERE 
             PostTypeId = 2 
         GROUP BY 
             ParentId) a ON p.Id = a.ParentId
    LEFT JOIN 
        (SELECT 
             UserId, 
             COUNT(*) AS Count 
         FROM 
             Badges 
         GROUP BY 
             UserId) b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, a.Count, b.Count
)

SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.ViewCount,
    pa.CommentCount,
    pa.VoteCount,
    pa.HistoryCount,
    pa.AnswerCount,
    pa.BadgesCount
FROM 
    PostActivity pa
ORDER BY 
    pa.ViewCount DESC, pa.CommentCount DESC
LIMIT 100;