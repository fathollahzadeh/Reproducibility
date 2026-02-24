WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        ARRAY_AGG(DISTINCT tag.TagName) AS Tags,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 
                (SELECT COUNT(*) 
                 FROM Votes v 
                 WHERE v.PostId = p.AcceptedAnswerId AND v.VoteTypeId = 2) 
            ELSE 0 
        END AS UpvotesOnAcceptedAnswer
    FROM 
        Posts p
        LEFT JOIN Comments c ON c.PostId = p.Id
        LEFT JOIN unnest(string_to_array(p.Tags, '><')) AS tag(TagName) ON TRUE
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId, p.AcceptedAnswerId
),
PostInteraction AS (
    SELECT 
        rp.*,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        COALESCE(b.Class, 0) AS BadgeClass
    FROM 
        RankedPosts rp
        INNER JOIN Users u ON u.Id = rp.OwnerUserId
        LEFT JOIN (
            SELECT 
                UserId, 
                MAX(Class) AS Class 
            FROM 
                Badges 
            WHERE 
                Date >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
            GROUP BY 
                UserId
        ) b ON b.UserId = u.Id
),
RecentVotes AS (
    SELECT 
        v.PostId,
        v.UserId,
        v.VoteTypeId,
        ROW_NUMBER() OVER (PARTITION BY v.PostId, v.UserId ORDER BY v.CreationDate DESC) AS VoteRank
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
)
SELECT 
    pi.PostId,
    pi.Title,
    pi.CreationDate,
    pi.Score,
    pi.ViewCount,
    pi.CommentCount,
    pi.OwnerDisplayName,
    pi.Reputation,
    pi.BadgeClass,
    pi.Tags,
    pi.UpvotesOnAcceptedAnswer,
    COALESCE(rv.VoteTypeId, 0) AS LastVoteType,
    CASE 
        WHEN pi.Rank <= 5 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    PostInteraction pi
    LEFT JOIN RecentVotes rv ON rv.PostId = pi.PostId AND rv.VoteRank = 1
WHERE 
    pi.ViewCount > (SELECT AVG(ViewCount) FROM Posts) 
    AND pi.Score > 0 
    AND (pi.BadgeClass IS NULL OR pi.BadgeClass < 3) 
ORDER BY 
    pi.Rank, 
    pi.CreationDate DESC
LIMIT 50;