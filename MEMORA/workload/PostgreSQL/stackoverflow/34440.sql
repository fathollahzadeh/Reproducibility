
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
),
UserVoteStatistics AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 5 THEN 1 ELSE 0 END) AS Favorites
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        DENSE_RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RevisionRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)  
),
RecentActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        CURRENT_DATE - u.LastAccessDate AS DaysInactive
    FROM 
        Users u
    WHERE 
        u.LastAccessDate > CURRENT_DATE - INTERVAL '6 months'
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score AS PostScore,
    rp.ViewCount,
    u.DisplayName AS AuthorDisplayName,
    u.Reputation AS AuthorReputation,
    ubc.BadgeCount,
    COALESCE(UVS.UpVotes, 0) AS UserUpVotes,
    COALESCE(UVS.DownVotes, 0) AS UserDownVotes,
    COALESCE(UVS.Favorites, 0) AS UserFavorites,
    phd.Comment AS LastPostHistoryComment,
    phd.CreationDate AS LastPostHistoryDate,
    phd.PostHistoryTypeId,
    CASE 
        WHEN DaysInactive <= INTERVAL '30 days' THEN 'Active'
        ELSE 'Inactive'
    END AS UserActivityStatus
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.PostId = u.Id
LEFT JOIN 
    UserVoteStatistics UVS ON u.Id = UVS.UserId
LEFT JOIN 
    UserBadgeCounts ubc ON u.Id = ubc.UserId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId AND phd.RevisionRank = 1
JOIN 
    RecentActiveUsers rau ON u.Id = rau.UserId
WHERE 
    rp.Rank <= 5  
ORDER BY 
    rp.Score DESC, u.Reputation DESC;
