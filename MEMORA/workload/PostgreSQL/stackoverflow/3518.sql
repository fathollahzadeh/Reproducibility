WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(upvote_count, 0) AS UpVotes,
        COALESCE(downvote_count, 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS upvote_count 
        FROM Votes 
        WHERE VoteTypeId = 2 
        GROUP BY PostId
    ) AS upvotes ON p.Id = upvotes.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS downvote_count 
        FROM Votes 
        WHERE VoteTypeId = 3 
        GROUP BY PostId
    ) AS downvotes ON p.Id = downvotes.PostId
),
FilteredPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 3
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
)
SELECT 
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.UpVotes,
    fp.DownVotes,
    ub.BadgeCount,
    ub.HighestBadgeClass
FROM 
    FilteredPosts fp
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = fp.Id)
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    fp.Score > (SELECT AVG(Score) FROM Posts) 
    AND (fp.UpVotes - fp.DownVotes) > 5
ORDER BY 
    fp.Score DESC
LIMIT 10;
