
WITH RECURSIVE TagHierarchy AS (
    SELECT Id, TagName, Count, ExcerptPostId, WikiPostId, 1 AS Level
    FROM Tags
    WHERE Count > 0
    UNION ALL
    SELECT t.Id, t.TagName, t.Count, t.ExcerptPostId, t.WikiPostId, th.Level + 1
    FROM Tags t
    JOIN TagHierarchy th ON t.Id = th.Id + 1
),
UserVotes AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.VoteTypeId) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        pt.Name AS PostType,
        COALESCE(ph.Comment, 'No comments') AS LastChangeComment,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS ChangeRank
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE p.CreationDate >= (CAST('2024-10-01' AS DATE) - INTERVAL '1 year')
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.OwnerUserId,
        pd.ViewCount,
        pd.Score,
        pd.PostType,
        COUNT(c.Id) AS CommentCount
    FROM PostDetails pd
    LEFT JOIN Comments c ON pd.PostId = c.PostId
    GROUP BY pd.PostId, pd.Title, pd.OwnerUserId, pd.ViewCount, pd.Score, pd.PostType
    HAVING COUNT(c.Id) > 5
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.Score,
    u.DisplayName AS Owner,
    uv.VoteCount,
    uv.Upvotes,
    uv.Downvotes,
    th.TagName AS TopTag
FROM TopPosts tp
INNER JOIN Users u ON tp.OwnerUserId = u.Id
LEFT JOIN UserVotes uv ON u.Id = uv.UserId
LEFT JOIN TagHierarchy th ON tp.PostId = th.Id
ORDER BY tp.Score DESC, tp.ViewCount DESC
LIMIT 10;
