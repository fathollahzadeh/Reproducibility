WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        ph.CreationDate AS PostHistoryDate,
        ph.UserId,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        Posts p
    INNER JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1  
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 10 THEN 1 END) AS DeletionVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS NetVoteScore
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS TotalBadges,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'  
    GROUP BY 
        b.UserId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    COALESCE(PostVotes.UpVotes, 0) AS UpVotes,
    COALESCE(PostVotes.DownVotes, 0) AS DownVotes,
    PostVotes.NetVoteScore,
    ph.PostHistoryDate,
    U.DisplayName AS UserName,
    COALESCE(rb.TotalBadges, 0) AS RecentBadgesCount,
    COALESCE(rb.BadgeNames, 'No recent badges') AS RecentBadgeNames
FROM 
    Posts p
LEFT JOIN 
    PostVotes ON p.Id = PostVotes.PostId
LEFT JOIN 
    RecursivePostHistory ph ON p.Id = ph.PostId AND ph.HistoryRank = 1
LEFT JOIN 
    Users U ON ph.UserId = U.Id
LEFT JOIN 
    RecentBadges rb ON U.Id = rb.UserId
WHERE 
    p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
ORDER BY 
    p.Score DESC, PostVotes.NetVoteScore DESC
LIMIT 100;