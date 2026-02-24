WITH RecentPostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.LastActivityDate,
        p.OwnerUserId,
        p.AnswerCount,
        p.Score,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS UserActivityRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),

PostVoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),

PostCloseReasons AS (
    SELECT 
        p.Id AS PostId,
        ph.Comment AS CloseReason,
        ph.CreationDate AS CloseDate
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    rpa.PostId,
    rpa.Title,
    rpa.OwnerDisplayName,
    rpa.PostTypeId,
    rpa.CreationDate,
    rpa.LastActivityDate,
    COALESCE(pvc.UpVotes, 0) AS UpVotes,
    COALESCE(pvc.DownVotes, 0) AS DownVotes,
    COALESCE(pvc.TotalVotes, 0) AS TotalVotes,
    pcr.CloseReason,
    pcr.CloseDate,
    ub.BadgeCount,
    ub.Badges,
    CASE 
        WHEN rpa.UserActivityRank = 1 THEN 'Most Active'
        WHEN rpa.UserActivityRank < 5 THEN 'Active'
        ELSE 'Inactive'
    END AS UserActivityStatus
FROM 
    RecentPostActivity rpa
LEFT JOIN 
    PostVoteCounts pvc ON rpa.PostId = pvc.PostId
LEFT JOIN 
    PostCloseReasons pcr ON rpa.PostId = pcr.PostId
LEFT JOIN 
    UserBadges ub ON rpa.OwnerUserId = ub.UserId
WHERE 
    (pcr.CloseDate IS NULL OR pcr.CloseDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days')
ORDER BY 
    rpa.LastActivityDate DESC,
    rpa.Score DESC
LIMIT 100;