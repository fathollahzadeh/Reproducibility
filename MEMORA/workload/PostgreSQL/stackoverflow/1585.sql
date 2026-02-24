WITH PostScores AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.OwnerUserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    GROUP BY 
        p.Id, p.Title, p.Score, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS MaxBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score + ps.UpVotes - ps.DownVotes AS NetScore,
        ROW_NUMBER() OVER (PARTITION BY ps.OwnerUserId ORDER BY ps.Score DESC) AS RowNum,
        ub.BadgeCount,
        ub.MaxBadgeClass
    FROM 
        PostScores ps
    JOIN 
        UserBadges ub ON ps.OwnerUserId = ub.UserId
    WHERE 
        ps.Score + ps.UpVotes - ps.DownVotes > 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.NetScore,
    tp.BadgeCount,
    CASE 
        WHEN tp.MaxBadgeClass = 1 THEN 'Gold'
        WHEN tp.MaxBadgeClass = 2 THEN 'Silver'
        WHEN tp.MaxBadgeClass = 3 THEN 'Bronze'
        ELSE 'No Badges'
    END AS HighestBadge,
    CASE 
        WHEN tp.RowNum <= 5 THEN 'Top'
        ELSE 'Others'
    END AS PostRank
FROM 
    TopPosts tp
WHERE 
    tp.BadgeCount > 0
ORDER BY 
    tp.NetScore DESC, tp.Title ASC
LIMIT 50;
