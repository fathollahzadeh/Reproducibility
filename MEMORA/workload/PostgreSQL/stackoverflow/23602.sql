
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id
    HAVING 
        COUNT(*) >= 5
),
ClosedPostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.PostHistoryTypeId) AS CloseCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        p.Id
),
CommentStats AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount,
        MAX(CreationDate) AS LastCommentDate
    FROM 
        Comments
    GROUP BY 
        PostId
),
FinalPerformanceAnalysis AS (
    SELECT 
        ru.DisplayName AS UserDisplayName,
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COUNT(DISTINCT bh.Id) AS BadgeCount,
        COALESCE(cs.CloseCount, 0) AS CloseCount,
        cs.LastClosedDate
    FROM 
        RankedPosts rp
    JOIN 
        Users ru ON rp.OwnerDisplayName = ru.DisplayName
    LEFT JOIN 
        CommentStats c ON rp.PostId = c.PostId
    LEFT JOIN 
        ClosedPostStats cs ON rp.PostId = cs.PostId
    LEFT JOIN 
        Badges bh ON bh.UserId = ru.Id
    WHERE 
        rp.UserPostRank = 1 
    GROUP BY 
        ru.DisplayName, rp.PostId, rp.Title, rp.CreationDate, c.CommentCount, cs.CloseCount, cs.LastClosedDate
)
SELECT 
    UserDisplayName,
    PostId,
    Title,
    CreationDate,
    CommentCount,
    BadgeCount,
    CloseCount,
    LastClosedDate,
    CASE 
        WHEN CloseCount > 0 THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    CASE 
        WHEN BadgeCount > 0 THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeStatus
FROM 
    FinalPerformanceAnalysis
WHERE 
    CommentCount IS NOT NULL
ORDER BY 
    BadgeCount DESC, CreationDate DESC;
