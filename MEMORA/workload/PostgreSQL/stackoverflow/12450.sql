
WITH PostStats AS (
  SELECT 
    p.Id AS PostID,
    p.Title,
    p.CreationDate,
    p.LastActivityDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    u.Id AS OwnerUserID,
    u.DisplayName AS OwnerDisplayName,
    COUNT(v.Id) AS VoteCount,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags
  FROM 
    Posts p
  JOIN 
    Users u ON p.OwnerUserId = u.Id
  LEFT JOIN 
    Votes v ON p.Id = v.PostId
  LEFT JOIN 
    UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS tag ON TRUE
  LEFT JOIN 
    Tags t ON tag = t.TagName
  GROUP BY 
    p.Id, u.Id, u.DisplayName
),
UserStats AS (
  SELECT 
    u.Id AS UserID,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS PostsCreated,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven
  FROM 
    Users u
  LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
  GROUP BY 
    u.Id, u.DisplayName
)
SELECT 
  ps.PostID,
  ps.Title,
  ps.CreationDate,
  ps.LastActivityDate,
  ps.ViewCount,
  ps.Score,
  ps.AnswerCount,
  ps.CommentCount,
  ps.FavoriteCount,
  ps.OwnerUserID,
  ps.OwnerDisplayName,
  ps.VoteCount,
  ps.Tags,
  us.UserID,
  us.DisplayName AS UserDisplayName,
  us.PostsCreated,
  us.QuestionsAsked,
  us.AnswersGiven
FROM 
  PostStats ps
JOIN 
  UserStats us ON ps.OwnerUserID = us.UserID
ORDER BY 
  ps.LastActivityDate DESC, ps.ViewCount DESC
LIMIT 100;
