WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Body,
        p.PostTypeId,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        (SELECT COUNT(*) 
         FROM Comments c 
         WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = p.Id 
         AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = p.Id 
         AND v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
),
PostHistoryCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS EditCount,
        SUM(CASE WHEN PostHistoryTypeId IN (4, 5, 6) THEN 1 ELSE 0 END) AS TitleOrBodyEditCount,
        SUM(CASE WHEN PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount
    FROM 
        PostHistory
    GROUP BY 
        PostId
),
FinalMetrics AS (
    SELECT 
        pd.*,
        COALESCE(phc.EditCount, 0) AS TotalEdits,
        COALESCE(phc.TitleOrBodyEditCount, 0) AS TitleOrBodyEdits,
        COALESCE(phc.CloseCount, 0) AS TotalCloses,
        ROW_NUMBER() OVER (PARTITION BY pd.PostTypeId ORDER BY pd.ViewCount DESC) AS RankByViews,
        LEAD(pd.Score) OVER (PARTITION BY pd.PostTypeId ORDER BY pd.Score DESC) AS NextPostScore
    FROM 
        PostDetails pd
    LEFT JOIN 
        PostHistoryCounts phc ON pd.PostId = phc.PostId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    OwnerDisplayName,
    CommentCount,
    UpVotes,
    DownVotes,
    TotalEdits,
    TitleOrBodyEdits,
    TotalCloses,
    RankByViews,
    NextPostScore,
    CASE 
        WHEN Score IS NULL THEN 'Unscored'
        WHEN Score < 0 THEN 'Negative Score'
        ELSE 'Positive Score'
    END AS ScoreStatus,
    CASE 
        WHEN TotalCloses > 0 THEN 
            'This post has been closed ' || TotalCloses || 
            ' time' || CASE WHEN TotalCloses > 1 THEN 's' END
        ELSE 'This post is open'
    END AS ClosureStatus
FROM 
    FinalMetrics
WHERE 
    (RankByViews <= 10 OR TitleOrBodyEdits > 0)
ORDER BY 
    PostTypeId, ViewCount DESC, Score DESC;
