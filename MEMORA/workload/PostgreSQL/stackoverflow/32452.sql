WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.Score > 0
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
UserVotingSummary AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    INNER JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEdited
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 6, 10) 
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    R.PostId,
    R.Title,
    R.CreationDate,
    R.Score,
    R.ViewCount,
    COALESCE(B.BadgeCount, 0) AS TotalBadges,
    COALESCE(B.GoldBadgeCount, 0) AS GoldBadges,
    COALESCE(V.TotalVotes, 0) AS TotalVotes,
    COALESCE(V.UpVotes, 0) AS UpVotes,
    COALESCE(V.DownVotes, 0) AS DownVotes,
    COALESCE(PH.HistoryCount, 0) AS EditHistoryCount,
    PH.LastEdited
FROM 
    RankedPosts R
JOIN 
    Users u ON u.Id = R.OwnerUserId
LEFT JOIN 
    UserBadges B ON B.UserId = u.Id
LEFT JOIN 
    UserVotingSummary V ON V.UserId = u.Id
LEFT JOIN 
    PostHistorySummary PH ON PH.PostId = R.PostId
WHERE 
    R.PostRank = 1
ORDER BY 
    R.Score DESC, 
    u.Reputation DESC
LIMIT 50;