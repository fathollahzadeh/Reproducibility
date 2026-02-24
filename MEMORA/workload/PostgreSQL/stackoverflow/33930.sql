
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        RANK() OVER (ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosePostReasons AS (
    SELECT 
        ph.PostId,
        ph.Comment AS CloseReason,
        ph.CreationDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
),
CommunityBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
)
SELECT 
    rp.Title,
    rp.Score,
    rp.ViewCount,
    u.DisplayName,
    tu.UpVotesCount,
    tu.DownVotesCount,
    COALESCE(cb.BadgeCount, 0) AS GoldBadgeCount,
    cr.CloseReason,
    cr.CreationDate AS CloseDate
FROM 
    RankedPosts rp
INNER JOIN 
    Posts p ON rp.Id = p.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    TopUsers tu ON u.Id = tu.UserId
LEFT JOIN 
    CommunityBadges cb ON u.Id = cb.UserId
LEFT JOIN 
    ClosePostReasons cr ON p.Id = cr.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, 
    u.DisplayName;
