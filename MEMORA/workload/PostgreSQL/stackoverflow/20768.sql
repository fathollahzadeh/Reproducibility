
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS ScoreRank,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY p.Id) AS UpVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY p.Id) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
HighlyVotedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        OwnerUserId,
        Score,
        ViewCount,
        ScoreRank,
        UpVoteCount,
        DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 10
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        b.Name AS BadgeName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, b.Name
),
PostHistoryReflections AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (11, 13) THEN ph.CreationDate END) AS LastActionDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    hp.PostId,
    hp.Title,
    hp.CreationDate,
    u.DisplayName AS Owner,
    (UPV.UpVoteCount - COALESCE(DWV.DownVoteCount, 0)) AS NetVotes,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN ph.LastClosedDate IS NOT NULL THEN 'Closed'
        WHEN ph.LastActionDate IS NOT NULL THEN 'Active'
        ELSE 'Inactive'
    END AS PostStatus
FROM 
    HighlyVotedPosts hp
LEFT JOIN 
    Users u ON hp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges b ON u.Id = b.UserId
LEFT JOIN 
    PostHistoryReflections ph ON hp.PostId = ph.PostId
LEFT JOIN 
    (SELECT 
        PostId, COUNT(*) AS UpVoteCount 
     FROM 
        Votes 
     WHERE 
        VoteTypeId = 2 
     GROUP BY 
        PostId) UPV ON hp.PostId = UPV.PostId
LEFT JOIN 
    (SELECT 
        PostId, COUNT(*) AS DownVoteCount 
     FROM 
        Votes 
     WHERE 
        VoteTypeId = 3 
     GROUP BY 
        PostId) DWV ON hp.PostId = DWV.PostId
WHERE 
    b.BadgeCount > 1 OR b.BadgeCount IS NULL
ORDER BY 
    hp.Score DESC;
