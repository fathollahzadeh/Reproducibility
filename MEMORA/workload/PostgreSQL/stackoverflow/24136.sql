
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2022-01-01' AND 
        p.CreationDate < '2024-10-01 12:34:56'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.PostTypeId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.CreationDate <= '2024-10-01 12:34:56' AND 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName
),
PostAnalytics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        ua.DisplayName,
        ua.UpVotes,
        ua.DownVotes,
        ua.BadgeCount,
        CASE 
            WHEN rp.Score IS NULL THEN 'No Score'
            WHEN rp.Score > 100 THEN 'Highly Rated'
            WHEN rp.Score BETWEEN 50 AND 100 THEN 'Moderately Rated'
            ELSE 'Low Rating'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    INNER JOIN 
        Users u ON rp.PostId = u.Id
    LEFT JOIN 
        UserActivity ua ON u.Id = ua.UserId
    WHERE 
        rp.rn <= 10 AND 
        (rp.ViewCount > 100 OR ua.BadgeCount > 0)
),
PostHistoryAnalytics AS (
    SELECT 
        p.Title,
        p.Id AS PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        COUNT(ph.Id) AS ChangeCount
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 10) AND 
        ph.CreationDate > '2023-10-01 12:34:56'
    GROUP BY 
        p.Title, p.Id, ph.PostHistoryTypeId, ph.CreationDate
)
SELECT 
    pa.Title,
    pa.ViewCount,
    pa.Score,
    pa.DisplayName,
    pa.UpVotes,
    pa.DownVotes,
    pa.ScoreCategory,
    COALESCE(ph.ChangeCount, 0) AS RecentChanges
FROM 
    PostAnalytics pa
LEFT JOIN 
    PostHistoryAnalytics ph ON pa.PostId = ph.PostId
WHERE 
    (pa.UpVotes > pa.DownVotes OR pa.ScoreCategory = 'Highly Rated')
ORDER BY 
    pa.Score DESC,
    pa.ViewCount DESC;
