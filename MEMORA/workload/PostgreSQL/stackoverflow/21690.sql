
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate > '2022-01-01' 
        AND (p.Score > 5 OR p.ViewCount > 100)
    GROUP BY 
        p.Id, pt.Name
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.BadgeCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5
),
PostWithHistory AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.ViewCount,
        fp.Score,
        fp.CommentCount,
        fp.UpVotes,
        fp.DownVotes,
        fp.BadgeCount,
        ph.CreationDate AS HistoryDate,
        pht.Name AS HistoryType,
        ROW_NUMBER() OVER (PARTITION BY fp.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        PostHistory ph ON fp.PostId = ph.PostId
    LEFT JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.CommentCount,
    p.UpVotes,
    p.DownVotes,
    p.BadgeCount,
    CONCAT('Title: ', p.Title, ' | Viewed: ', p.ViewCount, ' | Score: ', p.Score) AS PostSummary,
    CASE 
        WHEN p.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments'
    END AS CommentStatus,
    CASE 
        WHEN p.BadgeCount > 0 THEN CONCAT('User has ', p.BadgeCount, ' badges.')
        ELSE 'User has no badges.'
    END AS UserBadgeStatus,
    MAX(CASE 
        WHEN HistoryRank = 1 THEN HistoryType 
        ELSE NULL 
    END) AS LatestHistoryType
FROM 
    PostWithHistory p
GROUP BY 
    p.PostId, p.Title, p.CreationDate, p.ViewCount, p.Score, p.CommentCount, p.UpVotes, p.DownVotes, p.BadgeCount
HAVING 
    (SUM(p.UpVotes) - SUM(p.DownVotes) > 3 OR SUM(p.CommentCount) > 0)
ORDER BY 
    p.Score DESC, p.CreationDate DESC
LIMIT 100 OFFSET 0;
