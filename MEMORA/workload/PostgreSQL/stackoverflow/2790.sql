
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
PostWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Author,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = (SELECT p.OwnerUserId FROM Posts p WHERE p.Id = rp.PostId)) AS BadgeCount
    FROM 
        RecentPosts rp
),
RankedPosts AS (
    SELECT 
        pb.*,
        ROW_NUMBER() OVER (ORDER BY pb.Score DESC, pb.CommentCount DESC) AS Rank
    FROM 
        PostWithBadges pb
    WHERE 
        pb.BadgeCount > 0
)
SELECT 
    p.*,
    CASE 
        WHEN p.BadgeCount = 1 THEN 'Bronze'
        WHEN p.BadgeCount = 2 THEN 'Silver'
        WHEN p.BadgeCount > 2 THEN 'Gold'
        ELSE 'No Badge'
    END AS BadgeLevel
FROM 
    RankedPosts p
WHERE 
    p.Rank <= 10
ORDER BY 
    p.Rank;
