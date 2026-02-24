WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM 
        Badges
    GROUP BY 
        UserId
),
RecentVotes AS (
    SELECT 
        PostId, 
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostHistoryInfo AS (
    SELECT 
        PostId,
        MAX(CASE WHEN PostHistoryTypeId = 10 THEN CreationDate END) AS ClosedDate,
        MAX(CASE WHEN PostHistoryTypeId = 11 THEN CreationDate END) AS ReOpenedDate,
        MAX(CASE WHEN PostHistoryTypeId = 24 THEN CreationDate END) AS SuggestedEditDate
    FROM 
        PostHistory
    GROUP BY 
        PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    u.Reputation,
    hd.BadgeCount,
    hd.BadgeNames,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    COALESCE(rv.UpVotes, 0) AS TotalUpVotes,
    COALESCE(rv.DownVotes, 0) AS TotalDownVotes,
    PH.ClosedDate,
    PH.ReOpenedDate,
    PH.SuggestedEditDate
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges hd ON rp.OwnerUserId = hd.UserId
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId
LEFT JOIN 
    PostHistoryInfo PH ON rp.PostId = PH.PostId
WHERE 
    rp.RN = 1
ORDER BY 
    rp.CreationDate DESC
LIMIT 50;