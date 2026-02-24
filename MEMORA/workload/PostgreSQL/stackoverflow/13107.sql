
WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 5 THEN 1 ELSE 0 END) AS TagWikiCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        tags.TagName AS RelatedTag,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        LATERAL (SELECT unnest(string_to_array(p.Tags, ',')) AS TagName) AS tags ON TRUE
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
)
SELECT 
    um.UserId,
    um.Reputation,
    um.PostCount,
    um.QuestionCount,
    um.AnswerCount,
    um.TagWikiCount,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount AS PostAnswerCount,
    ps.CommentCount AS PostCommentCount,
    ps.FavoriteCount AS PostFavoriteCount,
    ps.RelatedTag
FROM 
    UserMetrics um
JOIN 
    PostStatistics ps ON um.UserId = ps.OwnerUserId
ORDER BY 
    um.Reputation DESC, 
    ps.Score DESC;
