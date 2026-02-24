
WITH UserScore AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Score,
        COUNT(DISTINCT ph.PostId) AS PostHistoryCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) DESC) AS RowNum
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.CreationDate <= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
), 
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        AVG(LENGTH(p.Body)) AS AvgBodyLength
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
    GROUP BY 
        p.Id, p.Title
), 
CloseReasonCounts AS (
    SELECT 
        ph.PostId,
        ph.Comment AS CloseReason,
        COUNT(*) AS ReasonCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.Comment
), 
AggregatedData AS (
    SELECT 
        us.Id AS UserId,
        us.DisplayName,
        us.Score,
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.VoteCount,
        ps.AvgBodyLength,
        COALESCE(cr.CloseReason, 'No close reasons') AS CloseReason,
        COALESCE(cr.ReasonCount, 0) AS ReasonCount,
        CASE 
            WHEN us.Score > 100 THEN 'High Scorer'
            WHEN us.Score BETWEEN 50 AND 100 THEN 'Medium Scorer'
            ELSE 'Low Scorer'
        END AS ScoreCategory
    FROM 
        UserScore us
    LEFT JOIN 
        PostStats ps ON us.Id = ps.PostId
    LEFT JOIN 
        CloseReasonCounts cr ON ps.PostId = cr.PostId
    WHERE 
        us.RowNum <= 10
)
SELECT 
    UserId,
    DisplayName,
    Score,
    PostId,
    Title,
    CommentCount,
    VoteCount,
    AvgBodyLength,
    CloseReason,
    ReasonCount,
    ScoreCategory
FROM 
    AggregatedData
ORDER BY 
    Score DESC, ReasonCount DESC, AvgBodyLength ASC
LIMIT 50;
