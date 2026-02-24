WITH UserBadgeCounts AS (
    SELECT
        UserId,
        COUNT(*) AS BadgeCount,
        MAX(Date) AS LastBadgeDate
    FROM Badges
    GROUP BY UserId
),
PostVoteCounts AS (
    SELECT  
        PostId,
        COUNT(CASE WHEN VoteTypeId IN (2, 8) THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotesCount
    FROM Votes
    GROUP BY PostId
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11, 12, 13)
    GROUP BY ph.PostId
),
FilteredPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(v.UpVotesCount, 0) - COALESCE(v.DownVotesCount, 0) AS ScoreDifference,
        COALESCE(bc.BadgeCount, 0) AS UserBadgeCount,
        ph.LastHistoryDate
    FROM 
        Posts p
    LEFT JOIN PostVoteCounts v ON p.Id = v.PostId
    LEFT JOIN UserBadgeCounts bc ON p.OwnerUserId = bc.UserId
    LEFT JOIN RecentPostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
        AND p.Score > 10
        AND (ph.LastHistoryDate IS NULL OR ph.LastHistoryDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '15 days')
),
RankedPosts AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.ScoreDifference,
        fp.UserBadgeCount,
        RANK() OVER (ORDER BY fp.ScoreDifference DESC, fp.UserBadgeCount DESC) AS PostRank
    FROM 
        FilteredPosts fp
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ScoreDifference,
    rp.UserBadgeCount,
    CASE 
        WHEN rp.ScoreDifference > 5 THEN 'High Engagement'
        WHEN rp.ScoreDifference BETWEEN 0 AND 5 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    RankedPosts rp
WHERE 
    rp.PostRank <= 10
ORDER BY 
    rp.PostRank,
    rp.UserBadgeCount DESC;