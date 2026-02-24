WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(v.Upvotes, 0) AS UpVotes,
        COALESCE(v.Downvotes, 0) AS DownVotes,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(ph.EditCount, 0) AS EditCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS Upvotes, SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes 
         FROM Votes GROUP BY PostId) v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT ParentId AS PostId, COUNT(*) AS AnswerCount 
         FROM Posts WHERE PostTypeId = 2 GROUP BY ParentId) a ON p.Id = a.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS EditCount 
         FROM PostHistory WHERE PostHistoryTypeId IN (4, 5, 6) GROUP BY PostId) ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 
),
SortedPostStats AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        UpVotes,
        DownVotes,
        CommentCount,
        AnswerCount,
        EditCount,
        ROW_NUMBER() OVER (ORDER BY UpVotes DESC, CreationDate ASC) AS Rank
    FROM 
        PostStats
)

SELECT 
    PostId,
    Title,
    CreationDate,
    UpVotes,
    DownVotes,
    CommentCount,
    AnswerCount,
    EditCount,
    Rank
FROM 
    SortedPostStats
WHERE 
    Rank <= 100;