
WITH RECURSIVE PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
),
PostActivity AS (
    SELECT 
        pp.Id AS PostId,
        pp.Title,
        pp.CreationDate,
        pp.Score,
        pp.ViewCount,
        pp.UpVotes,
        pp.DownVotes,
        ph.UserId,
        ph.CreationDate AS HistoryDate,
        pt.Name AS PostHistoryType
    FROM 
        PopularPosts pp
    JOIN 
        PostHistory ph ON pp.Id = ph.PostId
    LEFT JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate > (SELECT MAX(CreationDate) FROM Posts WHERE Id = pp.Id) - INTERVAL '30 days'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadge
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    pa.Title,
    pa.CreationDate,
    pa.Score,
    pa.ViewCount,
    pa.UpVotes,
    pa.DownVotes,
    pa.UserId,
    pa.HistoryDate,
    ub.BadgeCount,
    ub.HighestBadge
FROM 
    PostActivity pa
JOIN 
    UserBadges ub ON pa.UserId = ub.UserId
WHERE 
    pa.Score IS NOT NULL 
    AND pa.UpVotes > pa.DownVotes 
    AND ub.BadgeCount > 0
ORDER BY 
    pa.Score DESC, pa.ViewCount DESC;
