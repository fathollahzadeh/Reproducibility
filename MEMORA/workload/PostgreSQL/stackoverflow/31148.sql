
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS Author,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName
), FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.ViewCount, 
        rp.Author, 
        rp.CommentCount,
        (rp.UpVotes - rp.DownVotes) AS NetScore
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentCount > 5 
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Author,
    fp.ViewCount,
    fp.CommentCount,
    CASE 
        WHEN fp.NetScore > 0 THEN 'Positive'
        WHEN fp.NetScore < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment,
    COALESCE(UserBadges.BadgeCount, 0) AS BadgeCount
FROM 
    FilteredPosts fp
LEFT JOIN (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
) AS UserBadges ON UserBadges.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = fp.PostId)
WHERE 
    fp.CreationDate BETWEEN TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' AND TIMESTAMP '2024-10-01 12:34:56'
ORDER BY 
    fp.NetScore DESC, 
    fp.ViewCount DESC
LIMIT 10;
