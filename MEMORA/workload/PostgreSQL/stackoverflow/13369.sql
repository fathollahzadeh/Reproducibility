
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COUNT(c.Id) AS CommentCount,
        p.FavoriteCount,
        u.Reputation AS OwnerReputation,
        p.Tags,
        h.CreationDate AS LastEditDate,
        AVG(vot.BountyAmount) AS AverageBounty
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory h ON p.Id = h.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes vot ON p.Id = vot.PostId
    GROUP BY 
        p.Id, u.Reputation, p.PostTypeId, p.CreationDate, p.Score, 
        p.ViewCount, p.AnswerCount, p.FavoriteCount, 
        p.Tags, h.CreationDate
)
SELECT 
    PostId,
    PostTypeId,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    FavoriteCount,
    OwnerReputation,
    Tags,
    LastEditDate,
    AverageBounty
FROM 
    PostStats
ORDER BY 
    Score DESC,
    ViewCount DESC;
