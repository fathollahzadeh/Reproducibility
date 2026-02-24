
WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS VersionNumber
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) 
),
UserReputation AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
        LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AverageBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        p.Id
)
SELECT 
    p.Title,
    p.CreationDate AS PostCreationDate,
    ph.PostHistoryTypeId,
    ph.CreationDate AS HistoryDate,
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    ps.CommentCount,
    ps.AverageBounty,
    ps.UpVotes,
    ps.DownVotes
FROM 
    RecursivePostHistory ph
    JOIN Posts p ON p.Id = ph.PostId
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN UserReputation up ON u.Id = up.Id
    LEFT JOIN PostStatistics ps ON p.Id = ps.PostId
WHERE 
    ph.VersionNumber = 1 AND 
    (ph.PostHistoryTypeId = 10 OR ph.PostHistoryTypeId = 11) 
ORDER BY 
    p.CreationDate DESC, 
    ph.CreationDate DESC
LIMIT 50;
