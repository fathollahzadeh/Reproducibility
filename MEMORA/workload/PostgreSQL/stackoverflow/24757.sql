
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(DISTINCT ph.UserId) AS EditCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT PostId,
               SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
               SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT PostId,
               COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, v.UpVotes, v.DownVotes, c.CommentCount
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        ROW_NUMBER() OVER (ORDER BY Score DESC) AS TopRank
    FROM PostStatistics
    WHERE Score > 0
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.UpVotes,
    ps.DownVotes,
    ps.CommentCount,
    ps.EditCount,
    CASE WHEN tp.TopRank IS NOT NULL THEN 'Top' ELSE 'Regular' END AS PostCategory,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Tags t 
     JOIN (
        SELECT unnest(string_to_array(Tags, '><')) AS TagName
        FROM Posts
        WHERE Id = ps.PostId
     ) AS tmp ON t.TagName = tmp.TagName) AS TagList
FROM 
    PostStatistics ps
LEFT JOIN TopPosts tp ON ps.PostId = tp.PostId
WHERE 
    ps.Rank <= 5 OR tp.TopRank IS NOT NULL
ORDER BY 
    ps.Score DESC, ps.CreationDate ASC
OFFSET 5 ROWS;
