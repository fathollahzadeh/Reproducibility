
WITH RecursiveUserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        MIN(b.Date) AS FirstBadgeDate
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score
),
PostDetails AS (
    SELECT 
        p.Id,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Title,
        p.CreationDate,
        ap.ViewCount,
        ap.Score,
        ap.UpVoteCount,
        rb.BadgeCount,
        rb.FirstBadgeDate
    FROM 
        Posts p
    JOIN 
        ActivePosts ap ON p.Id = ap.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        RecursiveUserBadges rb ON u.Id = rb.UserId
    WHERE 
        p.PostTypeId = 1  
),
CloseReasonCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseReasonCount,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  
    GROUP BY 
        ph.PostId
),
FinalPostAnalysis AS (
    SELECT 
        pd.*,
        crc.CloseReasonCount,
        crc.FirstClosedDate
    FROM 
        PostDetails pd
    LEFT JOIN 
        CloseReasonCounts crc ON pd.Id = crc.PostId
)
SELECT 
    fpa.Title,
    fpa.OwnerDisplayName,
    fpa.ViewCount,
    fpa.Score,
    fpa.UpVoteCount,
    fpa.BadgeCount,
    fpa.FirstBadgeDate,
    COALESCE(fpa.CloseReasonCount, 0) AS CloseReasonCount,
    fpa.FirstClosedDate
FROM 
    FinalPostAnalysis fpa
ORDER BY 
    fpa.Score DESC, fpa.ViewCount DESC;
