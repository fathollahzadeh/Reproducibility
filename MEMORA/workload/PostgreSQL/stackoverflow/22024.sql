
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank,
        p.OwnerUserId,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS Downvotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId, u.DisplayName
),
TopPosts AS (
    SELECT *
    FROM RankedPosts
    WHERE PostRank <= 5
),
PostBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS UserBadges
    FROM 
        Badges b
    JOIN 
        Users u ON b.UserId = u.Id
    WHERE 
        u.Reputation > 5000
    GROUP BY 
        b.UserId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.Upvotes,
    tp.Downvotes,
    tp.CommentCount,
    COALESCE(pb.UserBadges, 'No Badges') AS TopUserBadges
FROM 
    TopPosts tp
LEFT JOIN 
    PostBadges pb ON tp.OwnerUserId = pb.UserId
WHERE 
    tp.Score > 0
AND 
    tp.ViewCount IS NOT NULL
AND 
    EXISTS (
        SELECT 1
        FROM PostHistory ph
        WHERE ph.PostId = tp.PostId
        AND ph.CreationDate > (SELECT MAX(CreationDate) FROM PostHistory WHERE PostHistoryTypeId = 12 AND PostId = tp.PostId)
    )
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
