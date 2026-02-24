WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Date > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY 
        b.UserId
),
PostHistoryData AS (
    SELECT
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS CloseReason,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserVoteStats AS (
    SELECT 
        v.UserId,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 1 THEN 1 ELSE 0 END) AS AcceptedCount
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        COALESCE(rb.BadgeCount, 0) AS RecentBadgeCount,
        COALESCE(phd.CloseReason, 'No Closure') AS LastCloseReason,
        phd.LastEditDate,
        usr.Reputation AS UserReputation,
        CASE WHEN uvs.UpvoteCount IS NULL THEN 0 ELSE uvs.UpvoteCount END AS TotalUpvotes,
        CASE WHEN uvs.DownvoteCount IS NULL THEN 0 ELSE uvs.DownvoteCount END AS TotalDownvotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentBadges rb ON rp.OwnerUserId = rb.UserId
    LEFT JOIN 
        PostHistoryData phd ON rp.PostId = phd.PostId
    LEFT JOIN 
        Users usr ON rp.OwnerUserId = usr.Id
    LEFT JOIN 
        UserVoteStats uvs ON rp.OwnerUserId = uvs.UserId
    WHERE 
        rp.rn = 1  
)
SELECT 
    FR.*,
    CASE 
        WHEN FR.TotalUpvotes > FR.TotalDownvotes THEN 'Positive' 
        WHEN FR.TotalDownvotes > FR.TotalUpvotes THEN 'Negative' 
        ELSE 'Neutral' 
    END AS VoteSentiment
FROM 
    FinalResults FR
ORDER BY 
    FR.RecentBadgeCount DESC, 
    FR.LastEditDate DESC,
    FR.UserReputation DESC;