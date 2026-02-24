
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostHistoryWithCloseReasons AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS CloseReason,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.Comment END) AS ReopenReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId, ph.CreationDate, ph.UserDisplayName
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        ur.Reputation,
        ur.BadgeCount,
        ur.HighestBadgeClass,
        pv.UpVotes,
        pv.DownVotes,
        COALESCE(ph.CloseReason, 'Not Closed') AS CloseReason
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        PostVotes pv ON rp.PostId = pv.PostId
    LEFT JOIN 
        PostHistoryWithCloseReasons ph ON rp.PostId = ph.PostId
    WHERE 
        rp.PostRank = 1 
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.Score,
    fr.CreationDate,
    fr.Reputation,
    fr.BadgeCount,
    fr.HighestBadgeClass,
    fr.UpVotes,
    fr.DownVotes,
    fr.CloseReason,
    CASE 
        WHEN fr.CloseReason IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS Status,
    CASE 
        WHEN fr.Reputation < 100 THEN 'Newbie'
        WHEN fr.Reputation BETWEEN 100 AND 1000 THEN 'Intermediate'
        ELSE 'Expert'
    END AS UserLevel
FROM 
    FinalResults fr
WHERE 
    fr.Reputation IS NOT NULL
ORDER BY 
    fr.Score DESC, fr.CreationDate DESC
LIMIT 100 OFFSET 0;
