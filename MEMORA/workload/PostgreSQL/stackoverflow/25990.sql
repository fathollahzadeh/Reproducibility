
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1  
    GROUP BY p.Id, p.Title, p.Body, p.Tags, p.OwnerUserId, u.DisplayName, p.CreationDate, p.ViewCount, p.Score
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName AS Editor,
        ph.CreationDate AS EditDate,
        ph.Comment,
        pht.Name AS ChangeType,
        ph.Text AS NewValue
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE ph.PostHistoryTypeId IN (4, 5, 6)  
),

FinalBenchmark AS (
    SELECT 
        r.PostId,
        r.Title,
        r.Body,
        r.Tags,
        r.OwnerDisplayName,
        r.CreationDate,
        r.ViewCount,
        r.Score,
        r.CommentCount,
        ph.Editor,
        ph.EditDate,
        ph.ChangeType,
        ph.NewValue,
        RANK() OVER (ORDER BY r.Score DESC, r.ViewCount DESC) AS OverallRank
    FROM RankedPosts r
    LEFT JOIN PostHistoryDetails ph ON r.PostId = ph.PostId
)

SELECT 
    PostId,
    Title,
    Body,
    Tags,
    OwnerDisplayName,
    CreationDate,
    ViewCount,
    Score,
    CommentCount,
    Editor,
    EditDate,
    ChangeType,
    NewValue,
    OverallRank
FROM FinalBenchmark
ORDER BY OverallRank, CreationDate DESC
LIMIT 100;
