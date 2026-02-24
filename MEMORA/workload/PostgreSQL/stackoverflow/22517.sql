WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.Score > (SELECT AVG(Score) FROM Posts WHERE CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), 
RecentVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Id = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN vt.Id = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        v.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate 
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        COALESCE(rv.UpVotesCount, 0) AS UpVotesCount,
        COALESCE(rv.DownVotesCount, 0) AS DownVotesCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        COALESCE(b.HighestBadgeClass, 0) AS HighestBadgeClass,
        cp.LastClosedDate,
        RANK() OVER (ORDER BY p.Score DESC) AS PostScoreRank
    FROM 
        RankedPosts p
    LEFT JOIN 
        RecentVotes rv ON p.PostId = rv.PostId
    LEFT JOIN 
        UserBadges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        ClosedPosts cp ON p.PostId = cp.PostId
    WHERE 
        (cp.LastClosedDate IS NULL OR cp.LastClosedDate < p.CreationDate) 
        AND p.PostRank <= 5 
)
SELECT 
    fr.*,
    CASE 
        WHEN fr.UpVotesCount > fr.DownVotesCount THEN 'Positive Engagement'
        WHEN fr.UpVotesCount < fr.DownVotesCount THEN 'Negative Engagement'
        ELSE 'Neutral Engagement'
    END AS EngagementLevel,
    (SELECT COUNT(DISTINCT pl.RelatedPostId) 
     FROM PostLinks pl 
     WHERE pl.PostId = fr.PostId) AS RelatedPostsCount
FROM 
    FinalResults fr
WHERE 
    fr.BadgeCount > 0
ORDER BY 
    fr.PostScoreRank, fr.CreationDate DESC;