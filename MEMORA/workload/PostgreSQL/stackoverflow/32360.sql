
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
),
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndeleteCount,
        MAX(ph.CreationDate) AS LastEdited
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
HighScoringPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Score, 
        rp.ViewCount, 
        rp.AnswerCount, 
        ub.BadgeCount
    FROM 
        RecentPosts rp
    JOIN 
        UsersWithBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE 
        rp.Score > 10
        AND ub.BadgeCount > 5
),
FinalSummary AS (
    SELECT 
        hsp.PostId, 
        hsp.Title, 
        hsp.Score, 
        hsp.ViewCount, 
        hsp.AnswerCount,
        ph.CloseReopenCount,
        ph.DeleteUndeleteCount,
        ph.LastEdited
    FROM 
        HighScoringPosts hsp
    JOIN 
        PostHistorySummary ph ON hsp.PostId = ph.PostId
)
SELECT 
    fs.PostId,
    fs.Title,
    fs.Score,
    fs.ViewCount,
    fs.AnswerCount,
    fs.CloseReopenCount,
    fs.DeleteUndeleteCount,
    fs.LastEdited,
    CASE 
        WHEN fs.CloseReopenCount > 2 THEN 'Frequently Closed/Reopened'
        ELSE 'Rarely Closed/Reopened'
    END AS ClosureStatus
FROM 
    FinalSummary fs
ORDER BY 
    fs.Score DESC, 
    fs.ViewCount DESC;
