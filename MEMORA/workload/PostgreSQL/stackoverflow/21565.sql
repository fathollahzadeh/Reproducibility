
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY p.Id), 0) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS CloseDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalPostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.UpVotes,
        rp.DownVotes,
        ph.CloseDate,
        ph.ReopenDate,
        ub.BadgeCount,
        ub.BadgeNames,
        ph.CloseReopenCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryDetails ph ON rp.PostId = ph.PostId
    LEFT JOIN 
        UserBadges ub ON ub.UserId = (
            SELECT 
                OwnerUserId 
            FROM 
                Posts 
            WHERE 
                Id = rp.PostId
            LIMIT 1
        )
    WHERE 
        rp.rn <= 10 
)
SELECT 
    Title,
    Score,
    ViewCount,
    UpVotes,
    DownVotes,
    CloseDate,
    ReopenDate,
    COALESCE(BadgeCount, 0) AS BadgeCount,
    COALESCE(BadgeNames, 'None') AS BadgeNames
FROM 
    FinalPostStats
WHERE 
    CloseReopenCount = 0 
ORDER BY 
    Score DESC, ViewCount DESC;
