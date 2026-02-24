WITH PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Posts a ON a.ParentId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    LEFT JOIN Comments c ON c.PostId = p.Id
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
), TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        AnswerCount,
        UpVotes,
        DownVotes,
        CommentCount,
        ROW_NUMBER() OVER (ORDER BY Score DESC, ViewCount DESC) AS PostRank
    FROM PostSummary
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.AnswerCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.CommentCount
FROM TopPosts tp
WHERE tp.PostRank <= 10;