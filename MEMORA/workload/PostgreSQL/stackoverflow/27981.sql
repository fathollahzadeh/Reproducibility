
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
), PostWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.UpVotesCount,
        rp.DownVotesCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON rp.PostId = b.UserId
    WHERE 
        rp.RecentPostRank = 1
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, rp.UpVotesCount, rp.DownVotesCount
), PostStats AS (
    SELECT 
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.UpVotesCount,
        p.DownVotesCount,
        CASE 
            WHEN p.BadgeCount > 5 THEN 'Expert' 
            WHEN p.BadgeCount BETWEEN 2 AND 5 THEN 'Intermediate' 
            ELSE 'Novice' 
        END AS UserLevel
    FROM 
        PostWithBadges p
)
SELECT 
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.UpVotesCount,
    ps.DownVotesCount,
    ps.UserLevel,
    CASE 
        WHEN ps.Score > 10 THEN 'Highly Engaged'
        WHEN ps.Score BETWEEN 5 AND 10 THEN 'Moderately Engaged'
        ELSE 'Less Engaged'
    END AS EngagementLevel
FROM 
    PostStats ps
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 20;
