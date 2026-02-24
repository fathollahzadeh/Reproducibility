WITH RecentActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted Answer Exists'
            ELSE 'No Accepted Answer'
        END AS AcceptedAnswerStatus,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountiesWon
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (9, 10) 
    GROUP BY 
        u.Id, u.Reputation
),
PostAnalysis AS (
    SELECT 
        p.Id,
        p.Title,
        u.DisplayName,
        u.Reputation,
        up.BadgeCount,
        p.Score,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(cl.Reason, 'N/A') AS CloseReason,
        NTILE(4) OVER (ORDER BY p.Score DESC) AS ScoreQuartile
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserReputation up ON u.Id = up.UserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) AS c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            ph.PostId,
            STRING_AGG(cr.Name, ', ') AS Reason
        FROM 
            PostHistory ph
        JOIN 
            CloseReasonTypes cr ON ph.Comment = CAST(cr.Id AS VARCHAR)
        WHERE 
            ph.PostHistoryTypeId IN (10, 11) 
        GROUP BY 
            ph.PostId
    ) AS cl ON p.Id = cl.PostId
)
SELECT 
    pa.Title,
    pa.DisplayName,
    pa.Reputation,
    pa.BadgeCount,
    pa.Score,
    pa.ViewCount,
    pa.CommentCount,
    pa.CloseReason,
    ra.AcceptedAnswerStatus,
    CASE 
        WHEN pa.Score > 0 THEN 'Positive'
        WHEN pa.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS ScoreSentiment,
    CASE 
        WHEN pa.Score > 50 THEN 'High Engagement'
        WHEN pa.Score BETWEEN 20 AND 50 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    PostAnalysis pa
LEFT JOIN 
    RecentActivePosts ra ON pa.Id = ra.PostId
WHERE 
    pa.Score IS NOT NULL 
    AND pa.ViewCount > 0
ORDER BY 
    pa.Reputation DESC, 
    pa.Score DESC
OFFSET 10 ROWS 
FETCH NEXT 20 ROWS ONLY;