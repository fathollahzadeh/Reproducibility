
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        pt.Name AS PostTypeName,
        u.DisplayName AS OwnerDisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount, 
        pt.Name, 
        u.DisplayName, 
        p.AcceptedAnswerId
), FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.PostTypeName,
        rp.OwnerDisplayName,
        rp.UpVotes,
        rp.DownVotes
    FROM RankedPosts rp
    WHERE rp.Rank <= 5
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.AnswerCount,
    fp.CommentCount,
    fp.PostTypeName,
    fp.OwnerDisplayName,
    fp.UpVotes,
    fp.DownVotes,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = fp.PostId) AS EditCount
FROM FilteredPosts fp
WHERE fp.ViewCount > 1000
ORDER BY fp.ViewCount DESC, fp.Score DESC;
