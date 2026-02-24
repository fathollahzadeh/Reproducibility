
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray,
        COALESCE(SUM(CASE WHEN pt.Id IN (1, 2) THEN 1 ELSE 0 END), 0) AS PostVoteCount
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag ON TRUE
    LEFT JOIN Tags t ON t.TagName = tag
    LEFT JOIN Votes pt ON pt.PostId = p.Id
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY p.Id, u.DisplayName, p.Title, p.Body, p.CreationDate, p.ViewCount, p.AnswerCount, p.CommentCount
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName AS EditorDisplayName,
        ph.Comment AS EditComment,
        ROW_NUMBER() OVER(PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRowNum
    FROM PostHistory ph
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.CreationDate,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.OwnerDisplayName,
    pd.TagsArray,
    pd.PostVoteCount,
    COALESCE(phd.HistoryRowNum, 0) AS LastEditVersion,
    COALESCE(phd.EditorDisplayName, 'No edits made') AS LastEditor,
    COALESCE(phd.HistoryDate, NULL) AS LastEditDate,
    COALESCE(phd.EditComment, 'N/A') AS LastEditComment
FROM PostDetails pd
LEFT JOIN PostHistoryDetails phd ON pd.PostId = phd.PostId AND phd.HistoryRowNum = 1
WHERE pd.PostVoteCount > 0
ORDER BY pd.ViewCount DESC, pd.CreationDate DESC
LIMIT 50;
