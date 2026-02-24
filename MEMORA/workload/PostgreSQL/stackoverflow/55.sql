
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Author,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, p.PostTypeId
), FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        Author,
        Rank,
        CommentCount
    FROM RankedPosts
    WHERE Rank <= 10
), RecentHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        M.HistoryType,
        M.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM PostHistory ph
    INNER JOIN (
        SELECT 
            PostId,
            UserDisplayName,
            CASE 
                WHEN PostHistoryTypeId IN (10, 11) THEN 'Closed/Reopened'
                WHEN PostHistoryTypeId IN (12, 13) THEN 'Deleted/Undeleted'
                ELSE 'Edited'
            END AS HistoryType
        FROM PostHistory
        WHERE CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 month')
    ) M ON ph.PostId = M.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate AS PostCreationDate,
    fp.ViewCount,
    fp.Score,
    fp.Author AS PostAuthor,
    fp.CommentCount,
    rh.HistoryDate,
    rh.HistoryType,
    rh.UserDisplayName AS Editor
FROM FilteredPosts fp
LEFT JOIN RecentHistory rh ON fp.PostId = rh.PostId AND rh.HistoryRank = 1
WHERE fp.ViewCount > 100
ORDER BY fp.Score DESC, fp.CreationDate DESC;
