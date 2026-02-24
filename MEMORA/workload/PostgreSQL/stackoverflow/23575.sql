WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank,
        CASE 
            WHEN p.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' THEN 'Old Post'
            ELSE 'Recent Post'
        END AS PostAgeCategory,
        array_agg(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        LATERAL (
            SELECT DISTINCT unnest(string_to_array(p.Tags, '<>')) AS TagName
        ) t ON true
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.LastActivityDate, p.PostTypeId
), 
PostVoteCounts AS (
    SELECT 
        PostId, 
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
RecentBadges AS (
    SELECT 
        u.Id AS UserId,
        b.Name AS BadgeName,
        COUNT(*) AS BadgeCount
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Date >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        u.Id, b.Name
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastActionDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS ClosedCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rpc.UpVotes,
    rpc.DownVotes,
    rp.ViewCount,
    rp.PostAgeCategory,
    rp.Rank,
    COALESCE(badge_info.BadgeName, 'No Badges') AS RecentBadge,
    ph.HistoryTypes,
    ph.LastActionDate,
    ph.ClosedCount 
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteCounts rpc ON rp.PostId = rpc.PostId
LEFT JOIN 
    RecentBadges badge_info ON badge_info.UserId = rp.PostId
LEFT JOIN 
    PostHistoryInfo ph ON rp.PostId = ph.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC, 
    ph.LastActionDate DESC;