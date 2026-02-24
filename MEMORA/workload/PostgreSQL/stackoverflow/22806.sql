
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END), 0) AS DeletionVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 6 THEN 1 ELSE 0 END), 0) AS CloseVoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL (SELECT unnest(string_to_array(p.Tags, '><')) AS TagName) AS t ON true
    GROUP BY 
        p.Id, p.Title, p.PostTypeId
),
RankedPosts AS (
    SELECT 
        ps.*,
        ROW_NUMBER() OVER (PARTITION BY ps.PostTypeId ORDER BY ps.UpVoteCount DESC, ps.CommentCount DESC) AS Rank,
        CASE 
            WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus
    FROM 
        PostStats ps
    LEFT JOIN 
        Posts p ON ps.PostId = p.Id
),
FilteredPosts AS (
    SELECT 
        PostId, 
        Title, 
        UpVoteCount, 
        DownVoteCount, 
        CommentCount, 
        Tags,
        Rank,
        PostStatus
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10 AND 
        PostStatus = 'Open' AND 
        (UpVoteCount - DownVoteCount) > 0
),
UserBadges AS (
    SELECT 
        UserId, 
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadgeCount,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadgeCount,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.UpVoteCount,
    fp.CommentCount,
    fp.Tags,
    ub.GoldBadgeCount,
    ub.SilverBadgeCount,
    ub.BronzeBadgeCount
FROM 
    FilteredPosts fp
LEFT JOIN 
    Users u ON fp.PostId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    EXISTS (
        SELECT 1 
        FROM Votes v 
        WHERE v.PostId = fp.PostId 
        AND v.VoteTypeId IN (2, 3) 
        GROUP BY v.PostId
        HAVING COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) > COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END)
    )
ORDER BY 
    fp.UpVoteCount DESC, 
    fp.CommentCount DESC;
