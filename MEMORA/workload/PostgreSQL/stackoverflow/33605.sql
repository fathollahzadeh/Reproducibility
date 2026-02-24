WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score IS NOT NULL
        AND p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) AS BadgeCount,
        (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id AND p.PostTypeId = 1) AS QuestionCount
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000 
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastUpdate
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '2 years' 
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
PostCommentsCount AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
CombinedData AS (
    SELECT 
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        ur.Reputation,
        ur.BadgeCount,
        ur.QuestionCount,
        phs.HistoryCount,
        phs.LastUpdate,
        pcc.CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserReputation ur ON rp.Id = ur.UserId
    LEFT JOIN 
        PostHistorySummary phs ON rp.Id = phs.PostId
    LEFT JOIN 
        PostCommentsCount pcc ON rp.Id = pcc.PostId
)
SELECT 
    Title,
    CreationDate,
    ViewCount,
    Score,
    Reputation,
    BadgeCount,
    QuestionCount,
    COALESCE(CommentCount, 0) AS CommentCount,
    COALESCE(HistoryCount, 0) AS HistoryEvents,
    CASE 
        WHEN LastUpdate IS NOT NULL THEN 'Updated'
        ELSE 'Never Updated'
    END AS UpdateStatus
FROM 
    CombinedData
WHERE 
    (Reputation > 0 OR BadgeCount > 0)
ORDER BY 
    Score DESC, CreationDate DESC
LIMIT 50;