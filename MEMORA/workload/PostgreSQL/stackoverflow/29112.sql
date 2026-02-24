
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.OwnerUserId, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        ps.*,
        CASE
            WHEN UpvoteCount > DownvoteCount THEN 'Popular'
            ELSE 'Less Popular'
        END AS Popularity
    FROM 
        PostStatistics ps
    WHERE 
        CommentCount > 5
        AND PostRank <= 10
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.Body,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    ps.GoldBadges,
    ps.SilverBadges,
    ps.BronzeBadges,
    ps.Popularity
FROM 
    FilteredPosts ps
ORDER BY 
    ps.UpvoteCount DESC, ps.CommentCount DESC;
