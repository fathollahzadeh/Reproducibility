WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS Author,
        u.Reputation AS AuthorReputation,
        COALESCE(a.AnswerCount, 0) AS TotalAnswers,
        COALESCE(c.CommentCount, 0) AS TotalComments,
        COALESCE(f.FavoriteCount, 0) AS TotalFavorites,
        STRING_AGG(DISTINCT t.TagName, ', ') AS AllTags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT ParentId, COUNT(*) AS AnswerCount 
         FROM Posts 
         WHERE PostTypeId = 2 
         GROUP BY ParentId) a ON p.Id = a.ParentId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments 
         GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS FavoriteCount 
         FROM PostHistory 
         WHERE PostHistoryTypeId = 12 
         GROUP BY PostId) f ON p.Id = f.PostId
    LEFT JOIN 
        Tags t ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName, u.Reputation, a.AnswerCount, c.CommentCount, f.FavoriteCount
    ORDER BY 
        p.CreationDate DESC
),
PostScores AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.AuthorReputation,
        rp.TotalAnswers,
        rp.TotalComments,
        rp.TotalFavorites,
        (rp.TotalAnswers * 2 + rp.TotalComments * 1 + rp.TotalFavorites * 3 + 
        CASE 
            WHEN rp.AuthorReputation >= 1000 THEN 10 
            ELSE 0 
        END) AS Score
    FROM 
        RecentPosts rp
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Author,
    ps.AuthorReputation,
    ps.TotalAnswers,
    ps.TotalComments,
    ps.TotalFavorites,
    ps.Score
FROM 
    PostScores ps
WHERE 
    ps.Score > 0
ORDER BY 
    ps.Score DESC, ps.AuthorReputation DESC
LIMIT 10;